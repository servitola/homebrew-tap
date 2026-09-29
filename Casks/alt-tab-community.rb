cask "alt-tab-community" do
  version "11.8.0.1"
  sha256 "112045e189f707d564e2a054c41292145f333d1e8d0bce0dc970cc86cf67470c"

  url "https://github.com/servitola/alt-tab-community/releases/download/community-#{version}/AltTab-#{version}.zip"
  name "AltTab Community"
  desc "Windows-like alt-tab, with every former Pro feature free"
  homepage "https://github.com/servitola/alt-tab-community"

  livecheck do
    url "https://raw.githubusercontent.com/servitola/alt-tab-community/master/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
  conflicts_with cask: "alt-tab"
  depends_on macos: :monterey

  app "AltTab.app"

  uninstall quit: "com.lwouis.alt-tab-macos"

  zap trash: [
    "~/Library/Application Support/com.lwouis.alt-tab-macos",
    "~/Library/Caches/com.lwouis.alt-tab-macos",
    "~/Library/Caches/com.plausiblelabs.crashreporter.data/com.lwouis.alt-tab-macos",
    "~/Library/Cookies/com.lwouis.alt-tab-macos.binarycookies",
    "~/Library/HTTPStorages/com.lwouis.alt-tab-macos",
    "~/Library/HTTPStorages/com.lwouis.alt-tab-macos.binarycookies",
    "~/Library/LaunchAgents/com.lwouis.alt-tab-macos.plist",
    "~/Library/Preferences/com.lwouis.alt-tab-macos.license.plist",
    "~/Library/Preferences/com.lwouis.alt-tab-macos.plist",
    "~/Library/Preferences/com.lwouis.alt-tab-macos.usage.plist",
  ]
end
