# Same token as homebrew/cask's zen on purpose: same app, our from-source build. The
# Brewfile must reference it as servitola/tap/zen, never a bare "zen": the core cask
# would replace this build and drop its policies.json (2026-08-30).
cask "zen" do
  version "1.24.2b-20261115.f384dac"
  sha256 "d69fb421c9aefbd1e89da8ac7e796c77af1d2c33acd82b9a70bbfe91a1d05880"

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
