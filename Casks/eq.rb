cask "eq" do
  version "2026.09.27.4"
  sha256 "5425e48800e15bbdb1292031f93a7a7ab69038afd86ab3dca7d0260d8be93b0d"

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
