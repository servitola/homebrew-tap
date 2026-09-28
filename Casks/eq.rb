cask "eq" do
  version "2026.09.28.2"
  sha256 "21fc19a5960c68d4b831eda1fbcf4aa4a19b50113449b979bc28ebf6a9d964fe"

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
  # EQ.app carries its LaunchAgent and registers it through SMAppService (`eq agent install`);
  # any `eq` command would do it too, this just starts the daemon without waiting for one.
  # Through `open`, not by running the binary: install steps run in Homebrew's sandbox, where
  # launchd answers "5: Input/output error" (see glasswings.rb), while LaunchServices starts
  # the process outside it. `-n` because the running daemon is EQ.app too, and LaunchServices
  # would only reactivate it. `open` hides eq's output, so it goes to files in the staged path
  # (per user; a fixed /tmp name could be planted as a symlink) and is printed from there. `-W`
  # waits for eq; when eq exits before `open` can block, the files are complete anyway.
  # A legacy ~/Library/LaunchAgents plist makes eq refuse, and says so.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/EQ.app"]
    run "/usr/bin/open", args:         ["-n", "-g", "-W", "-a", "{{appdir}}/EQ.app",
                                        "--stdout", "{{staged_path}}/agent-install.out",
                                        "--stderr", "{{staged_path}}/agent-install.err",
                                        "--args", "agent", "install"],
                         must_succeed: false,
                         print_stderr: false
    run "/bin/cat", args:         ["{{staged_path}}/agent-install.out", "{{staged_path}}/agent-install.err"],
                    must_succeed: false,
                    print_stdout: true
    remove ["agent-install.out", "agent-install.err"]
  end

  # Runs on upgrade too, which is wanted: SMAppService asks for an unregister before the
  # executable changes, and the postflight above registers the new one, restarting the
  # daemon on the new binary. It never touches a legacy plist, so no `uninstall launchctl:` —
  # that would delete the hand-installed plist on every upgrade. `--for-upgrade` leaves no
  # opt-out marker, which a user's `eq agent uninstall` writes; after a plain `brew uninstall`
  # nothing is left to start eq anyway.
  uninstall_preflight_steps do
    run "/usr/bin/open", args:         ["-n", "-g", "-W", "-a", "{{appdir}}/EQ.app",
                                        "--args", "agent", "uninstall", "--for-upgrade"],
                         must_succeed: false
  end

  zap launchctl: "com.servitola.eq",
      trash:     [
        "~/.cache/eq",
        "~/.config/eq",
        "~/Library/LaunchAgents/com.servitola.eq.plist",
        "~/Library/Logs/eq.log",
      ]

  caveats "If eq does not start, run `eq agent status`."
end
