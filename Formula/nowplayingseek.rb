class Nowplayingseek < Formula
  desc "Seek, skip and control whatever is Now Playing on macOS"
  homepage "https://github.com/servitola/nowplayingseek"
  url "https://github.com/servitola/nowplayingseek/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "205d38f54e06bbde1ec1aeb71fc24e2334eb967e9d3261eea073c4689de276fe"
  license "AGPL-3.0-only"
  head "https://github.com/servitola/nowplayingseek.git", branch: "main"

  depends_on :macos

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/nowplayingseek --version").strip
    assert_match "seek <time>", shell_output("#{bin}/nowplayingseek --help")
    assert_match "unknown command", shell_output("#{bin}/nowplayingseek bogus 2>&1", 64)
  end
end
