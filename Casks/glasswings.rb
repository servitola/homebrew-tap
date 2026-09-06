# Private repository: see Casks/forkgram.rb for why the cask carries this strategy.
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

cask "glasswings" do
  version "0.3"
  sha256 "bdadc7e448f77b5abfb45cf9947a86483a047ea6b849fff947e9be31373ddb82"

  url "https://github.com/servitola/glasswings/releases/download/v#{version}/Glasswings-#{version}.zip",
      using: PrivateGitHubReleaseDownloadStrategy
  name "Glasswings"
  desc "Liquid Glass notification banners: resident daemon plus CLI"
  homepage "https://github.com/servitola/glasswings"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Glasswings.app"
  binary "#{appdir}/Glasswings.app/Contents/Resources/bin/glasswings-send"

  # Glasswings is a resident daemon under launchd (KeepAlive), not something the user
  # opens. Homebrew has no LaunchAgent artifact for casks, so the agent is written here,
  # exactly as the repo's install.sh writes it, and `uninstall launchctl:` takes it down
  # on upgrade and uninstall. The quarantine attribute goes the way `--no-quarantine`
  # drops it: Developer ID signed, not notarized.
  # Still the legacy Ruby block, not `postflight_steps`: those run in Homebrew's cask
  # sandbox, where `launchctl bootstrap` answers "Bootstrap failed: 5: Input/output error"
  # (tried 2026-09-06). When the legacy block is removed, the daemon has to register its
  # own LaunchAgent (SMAppService) on first launch instead.
  # rubocop:disable Cask/InstallSteps
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Glasswings.app"]
    plist = "#{Dir.home}/Library/LaunchAgents/app.glasswings.daemon.plist"
    log = "#{Dir.home}/Library/Logs/glasswings.log"
    File.write(plist, <<~XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key>             <string>app.glasswings.daemon</string>
        <key>ProgramArguments</key>  <array><string>#{appdir}/Glasswings.app/Contents/MacOS/Glasswings</string></array>
        <key>RunAtLoad</key>         <true/>
        <key>KeepAlive</key>         <true/>
        <key>ProcessType</key>       <string>Adaptive</string>
        <key>LowPriorityIO</key>     <true/>
        <key>StandardOutPath</key>   <string>#{log}</string>
        <key>StandardErrorPath</key> <string>#{log}</string>
      </dict></plist>
    XML
    domain = "gui/#{Process.uid}"
    system_command "/bin/launchctl", args: ["bootout", "#{domain}/app.glasswings.daemon"], must_succeed: false
    system_command "/bin/launchctl", args: ["bootstrap", domain, plist]
    system_command "/bin/launchctl", args: ["enable", "#{domain}/app.glasswings.daemon"]
  end
  # rubocop:enable Cask/InstallSteps

  uninstall launchctl: "app.glasswings.daemon"

  zap trash: [
    "~/.config/glasswings",
    "~/.glasswings.sock",
    "~/Library/Logs/glasswings.log",
  ]
end
