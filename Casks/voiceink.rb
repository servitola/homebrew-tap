# Same token as homebrew/cask's voiceink on purpose: same app, our fork's build (see README).
cask "voiceink" do
  version "0"
  sha256 "0"

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
  depends_on macos: :sonoma

  app "VoiceInk.app"

  # Signed with the self-signed "VoiceInk Local Signing" identity, because the TCC grants
  # (mic, Accessibility, Screen Recording, Input Monitoring, Apple Events) are pinned to
  # its certificate; Gatekeeper would refuse the quarantined copy, so the attribute goes
  # the way `--no-quarantine` drops it. The app is expected to be running.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/VoiceInk.app"]
    run "/usr/bin/open", args: ["-a", "{{appdir}}/VoiceInk.app"]
  end

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
