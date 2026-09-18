class Nowplayingseek < Formula
  desc "Read the position of and seek whatever is Now Playing"
  homepage "https://github.com/servitola/nowplayingseek"
  url "https://github.com/servitola/nowplayingseek/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "0703e247f815ec7c6848519aa94e18eca9bbde1b0dc172988ad9a48f4c36cc1b"
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
