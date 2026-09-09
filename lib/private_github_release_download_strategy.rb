# typed: false
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
  def initialize(url, name, version, **meta)
    super
    m = url.match(%r{\Ahttps://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)\z})
    raise CurlDownloadStrategyError.new(url, "not a GitHub release asset URL") unless m

    @owner, @repo, @tag, @asset = m.captures
  end

  private

  def token
    @token ||= ENV["HOMEBREW_GITHUB_API_TOKEN"].presence ||
               ::Utils.safe_popen_read("/opt/homebrew/bin/gh", "auth", "token").strip
  end

  def asset_api_url
    @asset_api_url ||= begin
      json = curl_output("--silent", "--header", "Authorization: token #{token}",
                         "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}").stdout
      asset = JSON.parse(json).fetch("assets", []).find { |a| a["name"] == @asset }
      raise CurlDownloadStrategyError.new(url, "no asset #{@asset} in release #{@tag}") unless asset

      "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset["id"]}"
    end
  end

  def resolve_url_basename_time_file_size(url, timeout: nil)
    [url, @asset, nil, nil, nil, false]
  end

  def _fetch(url:, resolved_url:, timeout:)
    head = curl_output("--silent", "--head", "--header", "Accept: application/octet-stream",
                       "--header", "Authorization: token #{token}", asset_api_url, timeout:)
    location = parse_curl_output(head.stdout).fetch(:responses).filter_map { |r| r.fetch(:headers)["location"] }.last
    raise CurlDownloadStrategyError.new(url, "GitHub did not redirect #{asset_api_url} to the asset") unless location

    _curl_download location, temporary_path, timeout
  end
end
