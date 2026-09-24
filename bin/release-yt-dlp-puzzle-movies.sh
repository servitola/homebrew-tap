#!/usr/bin/env zsh
# Tag yt-dlp-puzzle-movies, create its GitHub release, point the formula at the tag.
# Usage: bin/release-yt-dlp-puzzle-movies.sh <version>      (e.g. 2026.09.24, or 2026.09.24.1)
# The tag goes to origin; the push mirror carries it to GitHub, where the release is made.
set -euo pipefail

src=${YT_DLP_PUZZLE_MOVIES_SRC:-$HOME/projects/yt-dlp-puzzle-movies}
gh_repo=servitola/yt-dlp-puzzle-movies
tap=${0:a:h:h}
formula=Formula/yt-dlp-puzzle-movies.rb
(( $# == 1 )) || { sed -n '2,4p' "$0" >&2; exit 2 }
version=$1
tag=v$version

[[ -d $src/.git ]] || { echo "no checkout at $src" >&2; exit 1 }
[[ -z $(git -C "$src" status --porcelain) ]] || { echo "$src has uncommitted changes" >&2; exit 1 }
[[ $(git -C "$src" branch --show-current) == main ]] || { echo "not on main" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] || { echo "main is not pushed to origin" >&2; exit 1 }
git -C "$src" rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "tag $tag already exists" >&2; exit 1 }

git -C "$src" tag -a "$tag" -m "yt-dlp-puzzle-movies $version"
git -C "$src" push -q origin "$tag"
head=$(git -C "$src" rev-parse "$tag^{commit}")
for _ in {1..12}; do
  [[ $(gh api "repos/$gh_repo/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] && break
  sleep 5
done
[[ $(gh api "repos/$gh_repo/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] ||
  { echo "GitHub did not receive $tag from the mirror" >&2; exit 1 }

gh release create "$tag" -R "$gh_repo" --verify-tag --title "yt-dlp-puzzle-movies $version" \
  --notes "Install: brew install servitola/tap/yt-dlp-puzzle-movies"

url="https://github.com/$gh_repo/archive/refs/tags/$tag.tar.gz"
sha=$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)
sed -i '' -e "s|^  url \".*\"\$|  url \"$url\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$tap/$formula"
grep -qF "url \"$url\"" "$tap/$formula" && grep -q "sha256 \"$sha\"" "$tap/$formula" || { echo "formula bump failed" >&2; exit 1 }
brew style "$tap/$formula"

git -C "$tap" commit -q -m "yt-dlp-puzzle-movies $version" -- "$formula"
git -C "$tap" push -q
head=$(git -C "$tap" rev-parse HEAD)
for _ in {1..12}; do
  [[ $(gh api repos/servitola/homebrew-tap/commits/main -q .sha 2>/dev/null) == "$head" ]] && break
  sleep 5
done
git -C "$(brew --repository servitola/tap)" pull -q --ff-only || true
echo "published $gh_repo $tag; formula yt-dlp-puzzle-movies -> $version"
