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
  # It is never loaded with launchctl: inside the install-steps sandbox both `launchctl
  # bootstrap gui/<uid>` and `launchctl load -w` answer "5: Input/output error", while the
  # very same plist bootstraps by hand a second later (retested on Homebrew 6.0.22,
  # 2026-09-09). launchd picks the agent up at the next login on its own; `open` covers
  # this session, and `uninstall launchctl:` has already booted the previous copy out by
  # the time these steps run.
  #
  # The log path is spelled with {{user}} because {{home}} is not one of the tokens
  # expanded inside step content — only the step's own `path` understands `base: :home`.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Glasswings.app"]
    write_file "Library/LaunchAgents/app.glasswings.daemon.plist", <<~XML, base: :home
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key>             <string>app.glasswings.daemon</string>
        <key>ProgramArguments</key>  <array><string>{{appdir}}/Glasswings.app/Contents/MacOS/Glasswings</string></array>
        <key>RunAtLoad</key>         <true/>
        <key>KeepAlive</key>         <true/>
        <key>ProcessType</key>       <string>Adaptive</string>
        <key>LowPriorityIO</key>     <true/>
        <key>StandardOutPath</key>   <string>/Users/{{user}}/Library/Logs/glasswings.log</string>
        <key>StandardErrorPath</key> <string>/Users/{{user}}/Library/Logs/glasswings.log</string>
      </dict></plist>
    XML
    run "/usr/bin/open", args: ["-a", "{{appdir}}/Glasswings.app"]
  end

  uninstall launchctl: "app.glasswings.daemon"

  zap trash: [
    "~/.config/glasswings",
    "~/.glasswings.sock",
    "~/Library/Logs/glasswings.log",
  ]
end
