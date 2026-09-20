# Same token as theboredteam/boring-notch's cask on purpose: same app, our fork's build
# (see README). The Brewfile must reference it as servitola/tap/boring-notch and the
# upstream tap must stay out, or `brew bundle` reinstalls the official build over this one.
cask "boring-notch" do
  version "2.7.3-20260920.23e67c6"
  sha256 "a19e19315408cf7c7eca8746f7a393864e452def206e18728758c6254788d4e8"

  url "https://github.com/servitola/boring-notch/releases/download/v#{version}/boringNotch-#{version}.zip"
  name "TheBoringNotch"
  desc "Notch companion, personal fork built nightly from TheBoredTeam/boring.notch"
  homepage "https://github.com/servitola/boring-notch"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+-\d{8}\.[0-9a-f]{7})$/i)
  end

  depends_on macos: :sonoma

  app "boringNotch.app"

  # Signed with Developer ID, not notarized: Gatekeeper would refuse the quarantined
  # copy, so the attribute goes the way `--no-quarantine` drops it. The identity is
  # stable across rebuilds on purpose — the Accessibility, Screen Recording and
  # Apple Events grants are pinned to it, and an ad-hoc signature would drop them
  # silently on every nightly.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/boringNotch.app"]
  end

  # No `auto_updates true`: the fork's Sparkle feed is our own and publishes nothing,
  # so brew, not the app, is what moves this build forward.
  uninstall quit: "theboringteam.boringnotch"

  zap trash: [
    "~/Library/Application Scripts/theboringteam.boringnotch",
    "~/Library/Containers/TheBoringNotch",
    "~/Library/Containers/theboringteam.boringnotch",
    "~/Library/Preferences/theboringteam.boringnotch.plist",
    "~/Library/Saved Application State/theboringteam.boringnotch.savedState",
  ]
end
