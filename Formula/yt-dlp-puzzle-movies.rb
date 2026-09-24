require_relative "../lib/private_github_release_download_strategy"

class YtDlpPuzzleMovies < Formula
  desc "Plugin for yt-dlp that downloads series and films from puzzle-movies.com"
  homepage "https://github.com/servitola/homebrew-tap"
  url "https://github.com/servitola/yt-dlp-puzzle-movies/releases/download/v2026.09.24/yt-dlp-puzzle-movies-2026.09.24.tar.gz",
      using: PrivateGitHubReleaseDownloadStrategy
  sha256 "7d5f09ce1b76b4ee379f7c09bff3d548d2e7e759c69edd66edcf6c0b01ea8a18"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on "yt-dlp"

  def install
    libexec.install "yt_dlp_plugins"
  end

  def caveats
    <<~EOS
      yt-dlp finds plugins only under ~/.config/yt-dlp/plugins, where a formula cannot write:
        mkdir -p ~/.config/yt-dlp/plugins
        ln -sfn #{opt_libexec} ~/.config/yt-dlp/plugins/yt-dlp-puzzle-movies
    EOS
  end

  test do
    (testpath/".config/yt-dlp/plugins").mkpath
    ln_s libexec, testpath/".config/yt-dlp/plugins/yt-dlp-puzzle-movies"
    # Without a URL yt-dlp exits 2, but the -v header has already listed the plugins it loaded.
    output = shell_output("#{formula_opt_bin("yt-dlp")}/yt-dlp -v 2>&1", 2)
    assert_match "Extractor Plugins: PuzzleMoviesIE", output
  end
end
