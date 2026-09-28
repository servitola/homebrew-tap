cask "eq" do
  version "2026.09.28"
  sha256 "c4e4675f497fb0688e4044b3a66bc129464cb635207db125e705bdf209e27ff5"

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
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/EQ.app"]
  end

  # Unloading on uninstall would also run on every upgrade and leave the agent unloaded.
  zap launchctl: "com.servitola.eq",
      trash:     [
        "~/.cache/eq",
        "~/.config/eq",
        "~/Library/LaunchAgents/com.servitola.eq.plist",
      ]
end
