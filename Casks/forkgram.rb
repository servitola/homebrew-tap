require_relative "../lib/private_github_release_download_strategy"

# Same token as homebrew/cask's forkgram on purpose: same app, our build (see README).
cask "forkgram" do
  version "7.2.7"
  sha256 "a116f9e48eb7332c4a7ff5e8e078e90c14555c33bc4c9b4d7c924dfc6ad170e3"

  url "https://github.com/servitola/telegram-desktop/releases/download/v#{version}-fork/Forkgram-#{version}.zip",
      using: PrivateGitHubReleaseDownloadStrategy
  name "Forkgram"
  desc "Telegram Desktop (Forkgram base) with personal patches"
  homepage "https://github.com/forkgram/tdesktop"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+)-fork$/i)
  end

  depends_on arch: :arm64
  depends_on macos: :ventura

  app "Forkgram.app"

  # Signed with Developer ID, not notarized: Gatekeeper would refuse the quarantined
  # copy, so the attribute goes the way `--no-quarantine` drops it.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Forkgram.app"]
  end

  uninstall quit: "com.tdesktop.Telegram"

  zap trash: [
    "~/Library/Application Support/Forkgram Desktop",
    "~/Library/Preferences/com.tdesktop.Telegram.plist",
    "~/Library/Saved Application State/com.tdesktop.Telegram.savedState",
  ]
end
