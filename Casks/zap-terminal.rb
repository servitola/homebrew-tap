# Token is not "zap": that is OWASP Zed Attack Proxy in homebrew/cask.
cask "zap-terminal" do
  version "0.1.0-20260928.8954864"
  sha256 "c431ad5d83ab18d40de7c77ec38c520a5901aa744bd98633622ad24b8d7e045b"

  url "https://github.com/servitola/zap-terminal/releases/download/v#{version}/Zap-#{version}.zip"
  name "Zap"
  desc "Terminal with AI and agent support, open-source Warp fork, nightly build"
  homepage "https://github.com/zerx-lab/zap"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+(?:-[\w.]+)?)$/i)
  end

  depends_on arch: :arm64
  depends_on :macos

  app "Zap.app"

  # Signed with Developer ID plus the TCC entitlements, not notarized: Gatekeeper would
  # refuse the quarantined copy, so the attribute goes the way `--no-quarantine` drops it.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Zap.app"]
  end

  uninstall quit: "dev.zap.Zap"

  zap trash: [
    "~/Library/Application Support/dev.zap.Zap",
    "~/Library/Logs/zap.log*",
    "~/Library/Preferences/dev.zap.Zap.plist",
    "~/Library/Saved Application State/dev.zap.Zap.savedState",
  ]
end
