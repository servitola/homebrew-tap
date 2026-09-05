cask "claude-counter" do
  version "1.0.0"
  sha256 "20ea00ab6891f340b2fd57ea9efffdfdffec8d674966106297d86dd0bde049be"

  url "https://github.com/servitola/claude_counter/releases/download/v#{version}/ClaudeCounter-#{version}.zip"
  name "Claude Counter"
  desc "Menu-bar indicator of Claude.ai usage limits"
  homepage "https://github.com/servitola/claude_counter"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "ClaudeCounter.app"

  # Signed with Developer ID, not notarized: Gatekeeper would refuse the quarantined
  # copy, so the attribute goes the way `--no-quarantine` drops it. A menu-bar app is
  # expected to be running, so an install or upgrade brings it back up.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/ClaudeCounter.app"]
    system_command "/usr/bin/open",
                   args: ["-a", "#{appdir}/ClaudeCounter.app"]
  end

  uninstall quit: "com.servitola.claudecounter"

  zap trash: [
    "~/Library/Caches/com.servitola.claudecounter",
    "~/Library/Preferences/com.servitola.claudecounter.plist",
    "~/Library/WebKit/com.servitola.claudecounter",
  ]
end
