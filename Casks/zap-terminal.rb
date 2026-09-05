# Token is not "zap": that is OWASP Zed Attack Proxy in homebrew/cask.
cask "zap-terminal" do
  version "0"
  sha256 "0"

  url "https://github.com/servitola/zap/releases/download/v#{version}/Zap-#{version}.zip"
  name "Zap"
  desc "Terminal with AI and agent support, open-source Warp fork, nightly build"
  homepage "https://github.com/zerx-lab/zap"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+(?:-[\w.]+)?)$/i)
  end

  depends_on arch: :arm64
  depends_on macos: :big_sur

  app "Zap.app"

  # Signed with Developer ID plus the TCC entitlements, not notarized: Gatekeeper would
  # refuse the quarantined copy, so the attribute goes the way `--no-quarantine` drops it.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Zap.app"]
  end

  zap trash: [
    "~/Library/Application Support/dev.zap.Zap",
    "~/Library/Logs/zap.log*",
    "~/Library/Preferences/dev.zap.Zap.plist",
    "~/Library/Saved Application State/dev.zap.Zap.savedState",
  ]
end
