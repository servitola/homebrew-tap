cask "transmission" do
  version "4.2.0-dev.20261031.a350ef0"
  sha256 "be776baf1d1510d0424baf373138717b1f3e32402e10db87190b8fb083015b9e"

  url "https://github.com/servitola/transmission/releases/download/v#{version}/Transmission-#{version}.zip"
  name "Transmission"
  desc "BitTorrent client, personal fork with native Liquid Glass UI"
  homepage "https://github.com/servitola/transmission"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+(?:-[\w.]+)?)$/i)
  end

  depends_on arch: :arm64
  # The binary links these Homebrew opt-libs by absolute path and dies in dyld without
  # them; `brew autoremove` has taken one out from under it before.
  depends_on formula: "gettext"
  depends_on formula: "libdeflate"
  depends_on formula: "libevent"
  depends_on formula: "libpsl"
  depends_on formula: "miniupnpc"
  depends_on macos: :tahoe

  app "Transmission.app"

  # The build is signed with Developer ID but not notarized, so Gatekeeper refuses
  # to open the quarantined copy Homebrew installs. Dropping the attribute is what
  # `brew install --no-quarantine` would do; done here so plain `brew upgrade` works.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Transmission.app"]
  end

  uninstall quit: "org.m0k.transmission"

  zap trash: [
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/org.m0k.transmission.sfl*",
    "~/Library/Application Support/Transmission",
    "~/Library/Caches/org.m0k.transmission",
    "~/Library/Preferences/org.m0k.transmission.plist",
    "~/Library/Saved Application State/org.m0k.transmission.savedState",
  ]
end
