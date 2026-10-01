cask "claude-counter" do
  version "1.1.1"
  sha256 "2b00c4adb8b49622894669a44464fc6e08b1a2fb518d1403412433f84ec77156"

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
  binary "#{appdir}/ClaudeCounter.app/Contents/MacOS/ClaudeCounter", target: "claude-counter"

  # No relaunch step after an upgrade: `open` inside an install step answers
  # "kLSNoExecutableErr: The executable is missing" for EVERY app —
  # /System/Applications/Calculator.app included — on Homebrew 6.0.22-304 /
  # macOS 26.6.2 (2026-09-11), and the step's failure aborts the install and then the
  # rollback, leaving no app installed at all.

  uninstall quit: "com.servitola.claudecounter"

  zap trash: [
    "~/Library/Caches/com.servitola.claudecounter",
    "~/Library/Preferences/com.servitola.claudecounter.plist",
    "~/Library/WebKit/com.servitola.claudecounter",
  ]
end
