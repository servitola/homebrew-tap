class Nowplayingseek < Formula
  desc "Read the position of and seek whatever is Now Playing"
  homepage "https://github.com/servitola/nowplayingseek"
  url "https://github.com/servitola/nowplayingseek/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "3f13d90ebfc75bd795030e2f71601cb721ccdc161ace4176b37017698abf3e7a"
  license "BSD-2-Clause"
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
