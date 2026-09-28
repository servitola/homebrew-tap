cask "eq" do
  version "2026.09.28.3"
  sha256 "275b1f500a59700e22c0218da914d58c343ecfb836fe3a380bed47918485a2d0"

  url "https://github.com/servitola/eq/releases/download/v#{version}/EQ-#{version}.zip"
  name "eq"
  desc "Headless per-device system equalizer, no icon, no window"
  homepage "https://github.com/servitola/eq"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "EQ.app"
  binary "#{appdir}/EQ.app/Contents/MacOS/eq", target: "eq"
  manpage "#{appdir}/EQ.app/Contents/Resources/man/eq.1"
  bash_completion "#{appdir}/EQ.app/Contents/Resources/completions/eq.bash"
  zsh_completion "#{appdir}/EQ.app/Contents/Resources/completions/_eq"
  fish_completion "#{appdir}/EQ.app/Contents/Resources/completions/eq.fish"

  # Signed with Developer ID, not notarized: Gatekeeper would refuse the quarantined copy.
  #
  # Nothing here starts the daemon: Homebrew's install-steps sandbox cannot launch an app —
  # `open -a EQ.app` fails with "error=-10810 kLSUnknownErr … Couldn't communicate with a helper
  # application" — so the first `eq` registers EQ.app's bundled LaunchAgent. No uninstall step
  # either: after an upgrade the daemon restarts itself on the new binary, after an uninstall it
  # exits once the binary is gone.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/EQ.app"]
  end

  zap launchctl: ["com.servitola.eq", "com.servitola.eq.daemon"],
      trash:     [
        "~/.cache/eq",
        "~/.config/eq",
        "~/Library/LaunchAgents/com.servitola.eq.plist",
        "~/Library/Logs/eq.log",
      ]

  caveats <<~EOS
    The daemon starts the first time you run `eq`: a login item "EQ" appears,
    and macOS asks once for System Audio Recording.
    If eq does not start, run `eq agent status`.
  EOS
end
