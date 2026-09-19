class Nowplayingseek < Formula
  desc "Seek, skip and control whatever is Now Playing on macOS"
  homepage "https://github.com/servitola/nowplayingseek"
  url "https://github.com/servitola/nowplayingseek/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "f63a3c74a9e139c4c86d4080b35f6f2b2c2e781df2e84a8d7d33df9e31db7e44"
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
