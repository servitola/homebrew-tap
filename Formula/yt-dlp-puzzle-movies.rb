require_relative "../lib/private_github_release_download_strategy"

class YtDlpPuzzleMovies < Formula
  desc "Plugin for yt-dlp that downloads series and films from puzzle-movies.com"
  homepage "https://github.com/servitola/homebrew-tap"
  url "https://github.com/servitola/yt-dlp-puzzle-movies/releases/download/v2026.09.24/yt-dlp-puzzle-movies-2026.09.24.tar.gz",
      using: PrivateGitHubReleaseDownloadStrategy
  sha256 "7d5f09ce1b76b4ee379f7c09bff3d548d2e7e759c69edd66edcf6c0b01ea8a18"
  revision 1

  livecheck do
    url :url
    strategy :github_latest
  end

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
