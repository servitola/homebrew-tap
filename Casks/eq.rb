cask "eq" do
  version "2026.10.09.1"
  sha256 "06450d1c0aebb5e64bfc2fec76a8f2e0f3eb36d2f5178bdd8998c1846817fbfd"

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
  # application" — so the first `eq` registers EQ.app's bundled LaunchAgent. After an upgrade the
  # daemon restarts itself on the new binary, after an uninstall it exits once the binary is gone.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/EQ.app"]
  end

  # The driver `eq mode driver` installs lives in /Library/Audio/Plug-Ins/HAL. Homebrew runs this
  # step on upgrade and reinstall as well, with nothing to tell them apart (only `signal` is
  # skipped there), so eq reads the brew command above it and removes the driver only on uninstall.
  # Through sh so a missing EQ.app cannot fail the uninstall; eq itself asks for the password.
  uninstall script: {
    executable:   "/bin/sh",
    args:         ["-c", '[ ! -x "$0" ] || "$0" driver uninstall --cask', "#{appdir}/EQ.app/Contents/MacOS/eq"],
    must_succeed: false,
  }

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

    Driver mode (no recording permission): `eq mode driver` installs the
    driver EQ.app carries, asking once for an administrator password.
    `brew uninstall eq` removes it again.
  EOS
end
