#!/usr/bin/env zsh
# Point Casks/alt-tab-community.rb at a release that scripts/community/release.sh already published.
# Nothing is signed here: that zip is notarized and stapled, and re-signing would void both.
# Usage: bin/bump-alt-tab-community.sh <version> [--no-push]
set -euo pipefail

tap=${0:a:h:h}
cask=Casks/alt-tab-community.rb
version=${1:?usage: bin/bump-alt-tab-community.sh <version> [--no-push]}
push=1; [[ ${2:-} == --no-push ]] && push=0
url=https://github.com/servitola/alt-tab-community/releases/download/community-$version/AltTab-$version.zip

cd "$tap"
# GitHub only mirrors this tap, with --force: a push made straight to it is erased by the next sync.
[[ $(git remote get-url origin) != *github.com* ]] || { echo "run this from the clone whose origin feeds the mirror, not the brew tap checkout" >&2; exit 1 }
git diff --quiet -- "$cask" || { echo "$cask has uncommitted changes" >&2; exit 1 }
sha=$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)
sed -i '' -E "s/^  version \".*\"/  version \"$version\"/; s/^  sha256 \".*\"/  sha256 \"$sha\"/" "$cask"
brew style "$cask"
git add "$cask"
git commit -q -m "alt-tab-community $version"
if (( push )); then git push -q origin main; fi
echo "alt-tab-community $version ($sha)"
