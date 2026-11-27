cask "claude-counter" do
  version "1.3.2"
  sha256 "c35f9e5de82783d4297b8497b900f8a540e74d64ea4c2d564273313cbf113290"

  url "https://github.com/servitola/claude_counter/releases/download/v#{version}/ClaudeCounter-#{version}.zip"
  name "Claude Counter"
  desc "Menu-bar indicator of Claude.ai usage limits"
  homepage "https://github.com/servitola/claude_counter"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "ClaudeCounter.app"
  binary "#{appdir}/ClaudeCounter.app/Contents/MacOS/ClaudeCounter", target: "claude-counter"

  # No relaunch step after an upgrade: `open` inside an install step answers
  # "kLSNoExecutableErr: The executable is missing" for EVERY app —
  # /System/Applications/Calculator.app included — on Homebrew 6.0.22-304 /
  # macOS 26.6.2 (2026-09-11), and the step's failure aborts the install and then the
  # rollback, leaving no app installed at all.

  uninstall quit: "com.servitola.claudecounter"

  zap trash: [
    "~/Library/Caches/com.servitola.claudecounter",
    "~/Library/Group Containers/NZNV266K59.com.servitola.claudecounter",
    "~/Library/Preferences/com.servitola.claudecounter.plist",
    "~/Library/WebKit/com.servitola.claudecounter",
  ]
end
