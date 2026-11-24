# Token is not "zap": that is OWASP Zed Attack Proxy in homebrew/cask.
cask "zap-terminal" do
  version "0.1.0-20261124.d245e05"
  sha256 "8fbea7d2b9de14c8ed3e30443a3cc8b00e7d87d021d83d630f0b36f7191d58bc"

  url "https://github.com/servitola/zap-terminal/releases/download/v#{version}/ZapNG-#{version}.zip"
  name "ZapNG"
  desc "Terminal with AI and agent support, open-source Warp fork, nightly build"
  homepage "https://github.com/q0wkp/zap-ng"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+(?:-[\w.]+)?)$/i)
  end

  depends_on arch: :arm64
  depends_on :macos

  app "ZapNG.app"

  # Signed with Developer ID plus the TCC entitlements, not notarized: Gatekeeper would
  # refuse the quarantined copy, so the attribute goes the way `--no-quarantine` drops it.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/ZapNG.app"]
  end

  uninstall quit: "dev.q0wkp.zapng"

  zap trash: [
    "~/Library/Application Support/dev.q0wkp.zapng",
    "~/Library/Logs/zap-ng.log*",
    "~/Library/Preferences/dev.q0wkp.zapng.plist",
    "~/Library/Saved Application State/dev.q0wkp.zapng.savedState",
  ]
end
