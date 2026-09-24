class YtDlpPuzzleMovies < Formula
  desc "Plugin for yt-dlp that downloads series and films from puzzle-movies.com"
  homepage "https://github.com/servitola/yt-dlp-puzzle-movies"
  url "https://github.com/servitola/yt-dlp-puzzle-movies/archive/refs/tags/v2026.09.24.2.tar.gz"
  sha256 "54c4c1a05b2b5b2bb08b32f02591ff29791cc9f2ee4d1f72248c32ca7c24890c"
  license "MIT"
  head "https://github.com/servitola/yt-dlp-puzzle-movies.git", branch: "main"

  depends_on "yt-dlp"

  # yt-dlp's virtualenv includes system site-packages, so a plugin linked into
  # HOMEBREW_PREFIX/lib/pythonX.Y/site-packages is on its sys.path and loads with no
  # further setup. X.Y follows whichever python@ yt-dlp is built on: when that moves,
  # this formula needs a revision bump to reinstall under the new path.
  def install
    python = Formula["yt-dlp"].deps.map(&:to_formula).find { |dep| dep.name.start_with?("python@") }
    (lib/"python#{python.version.major_minor}/site-packages").install "yt_dlp_plugins"
  end

  test do
    # Without a URL yt-dlp exits 2, but the -v header has already listed the plugins it loaded.
    output = shell_output("#{formula_opt_bin("yt-dlp")}/yt-dlp -v 2>&1", 2)
    assert_match "Extractor Plugins: PuzzleMoviesIE", output
  end
end
