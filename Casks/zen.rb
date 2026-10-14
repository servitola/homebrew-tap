# Same token as homebrew/cask's zen on purpose: same app, our from-source build. The
# Brewfile must reference it as servitola/tap/zen, never a bare "zen": the core cask
# would replace this build and drop its policies.json (2026-08-30).
cask "zen" do
  version "1.23.3b-20261014.b53d568"
  sha256 "c2c0ec22ebbf5f470129e0648791f43fd28b441e7b02fe35f8c0ebaf3e7ae384"

  url "https://github.com/servitola/zen-browser/releases/download/v#{version}/Zen-#{version}.zip"
  name "Zen Browser"
  desc "Web browser built weekly from source with auto-update disabled"
  homepage "https://github.com/servitola/zen-browser"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+[a-z]?-\d{8}\.[0-9a-f]{7})$/i)
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Zen.app"

  # Ad-hoc signed like every build of this job so far, so Gatekeeper would refuse the
  # quarantined copy: the attribute goes the way `--no-quarantine` drops it.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Zen.app"]
  end

  uninstall quit: "app.zen-browser.zen"

  zap trash: [
    "~/Library/Application Support/Zen",
    "~/Library/Caches/Mozilla/updates/Applications/Zen",
    "~/Library/Caches/Zen",
    "~/Library/Preferences/app.zen-browser.zen.plist",
    "~/Library/Saved Application State/app.zen-browser.zen.savedState",
  ]
end
