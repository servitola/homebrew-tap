# Same token as homebrew/cask's hammerspoon on purpose: same app, our fork's build (see README).
# The Brewfile must reference it as servitola/tap/hammerspoon and the official
# `cask "hammerspoon"` must stay out, or `brew bundle` reinstalls the upstream build over this one.
cask "hammerspoon" do
  version "1.1.1-20261003.21492aa"
  sha256 "073bab366a0bef0abab03233cf1d75a849ae9aa97d6c5f9a9c6eb4cea7526c15"

  url "https://github.com/servitola/hammerspoon/releases/download/v#{version}/Hammerspoon-#{version}.zip"
  name "Hammerspoon"
  desc "Desktop automation application, personal fork built from Hammerspoon/hammerspoon"
  homepage "https://github.com/servitola/hammerspoon"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+-\d{8}\.[0-9a-f]{7})$/i)
  end

  depends_on macos: :ventura

  app "Hammerspoon.app"
  binary "#{appdir}/Hammerspoon.app/Contents/Frameworks/hs/hs"

  # No `auto_updates true`: the fork's Sparkle feed is switched off, brew moves this build forward.
  uninstall quit: "org.hammerspoon.Hammerspoon"

  # Unlike the official cask, ~/.hammerspoon is not listed: here it is a dotfiles symlink.
  zap trash: [
    "~/Library/Application Support/com.crashlytics/org.hammerspoon.Hammerspoon",
    "~/Library/Caches/org.hammerspoon.Hammerspoon",
    "~/Library/Preferences/org.hammerspoon.Hammerspoon.plist",
    "~/Library/Saved Application State/org.hammerspoon.Hammerspoon.savedState",
  ]
end
