# typed: strict
# frozen_string_literal: true

# The release lives in a private repository. GitHub serves private assets only through
# the API, by asset id, with a token, and answers with a redirect to a signed storage URL
# that must be fetched WITHOUT the token (curl forwards custom headers across hosts and
# the storage rejects a request carrying two credentials). Homebrew dropped its own
# GitHubPrivateRepositoryReleaseDownloadStrategy, hence this one. Token: the local `gh`
# login, or HOMEBREW_GITHUB_API_TOKEN when set.
#
# Casks reach this with `require_relative "../lib/..."`: a cask file is instance_eval'd
# with its own path, so the tap's own Ruby loads the same way it would in a formula.
class PrivateGitHubReleaseDownloadStrategy < CurlDownloadStrategy
  ASSET_URL_PATTERN = %r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)\z}

  sig { params(url: String, name: String, version: T.nilable(T.any(String, Version)), meta: T.untyped).void }
  def initialize(url, name, version, **meta)
    super

    match = ASSET_URL_PATTERN.match(url)
    raise CurlDownloadStrategyError.new(url, "not a GitHub release asset URL") if match.nil?

    # `to_s` rather than `T.must`, which Homebrew's rubocop forbids: every group in the
    # pattern needs at least one character, so a matched group is never nil.
    @owner = T.let(match[1].to_s, String)
    @repo = T.let(match[2].to_s, String)
    @tag = T.let(match[3].to_s, String)
    @asset = T.let(match[4].to_s, String)

    @token = T.let(nil, T.nilable(String))
    @gh_executable = T.let(nil, T.nilable(Pathname))
    @asset_api_url = T.let(nil, T.nilable(String))
  end

  private

  sig { returns(String) }
  def token
    @token ||= ENV["HOMEBREW_GITHUB_API_TOKEN"].presence || gh_token
  end

  # Brew's Ruby runs with a scrubbed PATH — shims, /usr/bin, /bin, /usr/sbin, /sbin —
  # so `which("gh")` finds nothing and the executable has to be named by prefix.
  sig { returns(T.nilable(Pathname)) }
  def gh_executable
    @gh_executable ||= [HOMEBREW_PREFIX/"bin/gh", *::Utils.which("gh")]
                       .find { |path| path.file? && path.executable? }
  end

  sig { returns(String) }
  def gh_token
    gh = gh_executable
    if gh.nil?
      raise CurlDownloadStrategyError.new(
        url, "this release is in a private repository, so Homebrew needs a GitHub token " \
             "that can read it: `brew install gh && gh auth login`, or set " \
             "HOMEBREW_GITHUB_API_TOKEN"
      )
    end

    token = begin
      ::Utils.safe_popen_read(gh, "auth", "token").strip
    rescue ErrorDuringExecution
      ""
    end
    return token if token.presence

    raise CurlDownloadStrategyError.new(
      url, "`#{gh} auth token` gave nothing back: run `gh auth login`, or set " \
           "HOMEBREW_GITHUB_API_TOKEN"
    )
  end

  sig { returns(String) }
  def asset_api_url
    @asset_api_url ||= begin
      json = curl_output("--silent", "--header", "Authorization: token #{token}",
                         "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}").stdout
      assets = T.cast(JSON.parse(json), T::Hash[String, T.untyped]).fetch("assets", [])
      asset = assets.find { |candidate| candidate["name"] == @asset }
      raise CurlDownloadStrategyError.new(url, "no asset #{@asset} in release #{@tag}") if asset.nil?

      "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset["id"]}"
    end
  end

  sig { override.params(url: String, timeout: T.nilable(T.any(Float, Integer))).returns(URLMetadata) }
  def resolve_url_basename_time_file_size(url, timeout: nil)
    [url, @asset, nil, nil, nil, false]
  end

  sig {
    override.params(url: String, resolved_url: String, timeout: T.nilable(T.any(Float, Integer)))
            .returns(T.nilable(SystemCommand::Result))
  }
  def _fetch(url:, resolved_url:, timeout:)
    head = curl_output("--silent", "--head", "--header", "Accept: application/octet-stream",
                       "--header", "Authorization: token #{token}", asset_api_url, timeout:)
    location = parse_curl_output(head.stdout).fetch(:responses).filter_map { |r| r.fetch(:headers)["location"] }.last
    raise CurlDownloadStrategyError.new(url, "GitHub did not redirect #{asset_api_url} to the asset") if location.nil?

    _curl_download location, temporary_path, timeout
  end
end
