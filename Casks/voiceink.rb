# Same token as homebrew/cask's voiceink on purpose: same app, our fork's build (see README).
cask "voiceink" do
  version "2.22-20261102.77c84d5"
  sha256 "d8523efa1dc88acf71983e96c41ddf3e699311aca1edf33a30c6997096d0c62d"

  url "https://github.com/servitola/VoiceInk/releases/download/v#{version}/VoiceInk-#{version}.zip"
  name "VoiceInk"
  desc "Voice to text app, personal fork built nightly from Beingpax/VoiceInk"
  homepage "https://github.com/servitola/VoiceInk"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+-\d{8}\.[0-9a-f]{7})$/i)
  end

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "VoiceInk.app"

  uninstall quit: "com.prakashjoshipax.VoiceInk"

  zap trash: [
    "~/Library/Application Support/com.prakashjoshipax.VoiceInk",
    "~/Library/Application Support/VoiceInk",
    "~/Library/Caches/com.prakashjoshipax.VoiceInk",
    "~/Library/HTTPStorages/com.prakashjoshipax.VoiceInk",
    "~/Library/Preferences/com.prakashjoshipax.VoiceInk.plist",
    "~/Library/Saved Application State/com.prakashjoshipax.VoiceInk.savedState",
  ]
end
