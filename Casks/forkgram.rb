# The release lives in a private repository. GitHub serves private assets only through
# the API, by asset id, with a token, and answers with a redirect to a signed storage URL
# that must be fetched WITHOUT the token (curl forwards custom headers across hosts and
# the storage rejects a request carrying two credentials). Homebrew dropped its own
# GitHubPrivateRepositoryReleaseDownloadStrategy, hence this one. Token: the local `gh`
# login, or HOMEBREW_GITHUB_API_TOKEN when set.
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

# Same token as homebrew/cask's forkgram on purpose: same app, our build (see README).
cask "forkgram" do
  version "7.2.7"
  sha256 "a116f9e48eb7332c4a7ff5e8e078e90c14555c33bc4c9b4d7c924dfc6ad170e3"

  url "https://github.com/servitola/telegram-desktop/releases/download/v#{version}-fork/Forkgram-#{version}.zip",
      using: PrivateGitHubReleaseDownloadStrategy
  name "Forkgram"
  desc "Telegram Desktop (Forkgram base) with personal patches"
  homepage "https://github.com/forkgram/tdesktop"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+)-fork$/i)
  end

  depends_on arch: :arm64
  depends_on macos: :ventura

  app "Forkgram.app"

  # Signed with Developer ID, not notarized: Gatekeeper would refuse the quarantined
  # copy, so the attribute goes the way `--no-quarantine` drops it.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Forkgram.app"]
  end

  uninstall quit: "com.tdesktop.Telegram"

  zap trash: [
    "~/Library/Application Support/Forkgram Desktop",
    "~/Library/Preferences/com.tdesktop.Telegram.plist",
    "~/Library/Saved Application State/com.tdesktop.Telegram.savedState",
  ]
end
