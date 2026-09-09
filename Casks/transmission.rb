cask "transmission" do
  version "4.2.0-dev.20260905"
  sha256 "41857ec38cdc4963327111645404d207cfdf3aa9ec368613d78af11bf1044056"

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
