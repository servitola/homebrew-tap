cask "polaska" do
  version "0.1"
  sha256 "d7ea3a4ee52ff8e656f17848f1f770c7c19fecaebc5a6ab52879f571cc58ab12"

  url "https://github.com/servitola/polaska/releases/download/v#{version}/Polaska-#{version}.dmg"
  name "Polaska"
  desc "Glass tab strip pinned under the browser window"
  homepage "https://github.com/servitola/polaska"

  livecheck do
    url "https://servitola.github.io/polaska/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Polaska.app"

  uninstall quit: "com.servitola.polaska"

  zap trash: [
    "~/Library/Caches/com.servitola.polaska",
    "~/Library/HTTPStorages/com.servitola.polaska",
    "~/Library/HTTPStorages/com.servitola.polaska.binarycookies",
    "~/Library/Logs/Polaska.log",
    "~/Library/Preferences/com.servitola.polaska.plist",
  ]

  caveats <<~EOS
    Polaska draws tabs only for browsers that run its extension, and follows
    their windows through the Accessibility permission:
      System Settings → Privacy & Security → Accessibility → Polaska
  EOS
end
