cask "eq" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/servitola/eq/releases/download/v#{version}/EQ-#{version}.zip"
  name "eq"
  desc "Headless per-device system equalizer, no icon, no window"
  homepage "https://github.com/servitola/eq"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch:  :arm64
  depends_on macos: :sonoma

  app "EQ.app"
  binary "#{appdir}/EQ.app/Contents/MacOS/eq", target: "eq"

  # Signed with Developer ID, not notarized: Gatekeeper would refuse the quarantined copy.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/EQ.app"]
  end

  zap trash: [
    "~/.cache/eq",
    "~/.config/eq",
  ]
end
