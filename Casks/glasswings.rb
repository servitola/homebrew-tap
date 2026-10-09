require_relative "../lib/private_github_release_download_strategy"

cask "glasswings" do
  version "0.3"
  sha256 "bdadc7e448f77b5abfb45cf9947a86483a047ea6b849fff947e9be31373ddb82"

  url "https://github.com/servitola/glasswings/releases/download/v#{version}/Glasswings-#{version}.zip",
      using: PrivateGitHubReleaseDownloadStrategy
  name "Glasswings"
  desc "Liquid Glass notification banners: resident daemon plus CLI"
  homepage "https://github.com/servitola/homebrew-tap"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Glasswings.app"
  binary "#{appdir}/Glasswings.app/Contents/Resources/bin/glasswings-send"

  # Homebrew replaces the app artifact without quitting what is running, and
  # `uninstall` directives come from the *installed* version, so the `quit:`
  # below cannot help on the upgrade that first introduces it. Without this the
  # old daemon survives with the socket bound, and the postflight `open` only
  # reactivates it — LaunchServices dedupes by bundle id, so the new bundle
  # never gets a process. Killing it here, after the old artifact is gone and
  # before the new one lands, is what makes that upgrade land.
  preflight_steps do
    run "/usr/bin/pkill", args: ["-x", "Glasswings"], must_succeed: false
  end

  # Glasswings is a resident launchd agent, and casks have no LaunchAgent
  # artifact — but nothing here has to write one any more. The app ships the
  # agent description at Contents/Library/LaunchAgents/ and registers it
  # through SMAppService on first launch, which is also what sidesteps the
  # install-steps sandbox: inside these steps both `launchctl bootstrap
  # gui/<uid>` and `launchctl load -w` answer "5: Input/output error", while
  # the same plist bootstraps by hand a second later (Homebrew 6.0.22).
  #
  # What is left is clearing quarantine — the build is signed with a Developer
  # ID but not notarised — and opening the bundle once, which registers the
  # agent. Homebrew 7's step sandbox refuses every `open` (-10810, verified on
  # 7.0.7 with Calculator), and a failing step rolls the whole install back, so
  # the launch is best-effort and the caveat asks for it instead.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Glasswings.app"]
    run "/usr/bin/open", args: ["-a", "{{appdir}}/Glasswings.app"], must_succeed: false
  end

  # `launchctl:` stops the registered agent and deletes any hand-written
  # ~/Library/LaunchAgents plist an older version left behind. `quit:` catches
  # the copy the postflight `open` started on versions that predate the agent —
  # launchctl cannot see that one, so an upgrade used to orphan it.
  uninstall launchctl: ["com.servitola.glasswings.daemon", "app.glasswings.daemon"],
            quit:      "com.servitola.glasswings"

  zap trash: [
    "~/.config/glasswings",
    "~/.glasswings.sock",
    "~/Library/Logs/glasswings.log",
  ]

  caveats <<~EOS
    Open Glasswings once after every install or upgrade: that launch registers
    the login agent, and the daemon runs from launchd from then on.
  EOS
end
