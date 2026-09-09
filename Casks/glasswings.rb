require_relative "../lib/private_github_release_download_strategy"

cask "glasswings" do
  version "0.3"
  sha256 "bdadc7e448f77b5abfb45cf9947a86483a047ea6b849fff947e9be31373ddb82"

  url "https://github.com/servitola/glasswings/releases/download/v#{version}/Glasswings-#{version}.zip",
      using: PrivateGitHubReleaseDownloadStrategy
  name "Glasswings"
  desc "Liquid Glass notification banners: resident daemon plus CLI"
  homepage "https://github.com/servitola/homebrew-tap"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Glasswings.app"
  binary "#{appdir}/Glasswings.app/Contents/Resources/bin/glasswings-send"

  # Glasswings is a resident launchd daemon, not something the user opens, and casks have
  # no LaunchAgent artifact — so the agent is written here exactly as the repo's
  # install.sh writes it, and `uninstall launchctl:` takes it down on upgrade.
  #
  # This is the only cask in the tap still on the legacy Ruby block: inside the
  # `postflight_steps` sandbox `launchctl bootstrap` answers "Bootstrap failed: 5:
  # Input/output error" (2026-09-06), so bin/publish-app.sh skips the Cask/InstallSteps
  # cop. When Homebrew drops the block, Glasswings must register its own agent
  # (SMAppService) at first launch.
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

  uninstall launchctl: "app.glasswings.daemon"

  zap trash: [
    "~/.config/glasswings",
    "~/.glasswings.sock",
    "~/Library/Logs/glasswings.log",
  ]
end
