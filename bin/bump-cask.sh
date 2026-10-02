#!/usr/bin/env zsh
# Point Casks/<token>.rb at an asset its own release script already published.
# Nothing is signed here: such an asset is notarized and stapled, and re-signing would void both.
# Usage: bin/bump-cask.sh <token> <version> <asset-url> [--no-push]
set -euo pipefail

tap=${0:a:h:h}
(( $# >= 3 )) || { sed -n '2,4p' "$0" >&2; exit 2 }
token=$1 version=$2 url=$3
push=1; [[ ${4:-} == --no-push ]] && push=0
cask=Casks/$token.rb

cd "$tap"
[[ -f $cask ]] || { echo "no cask $tap/$cask" >&2; exit 1 }
# GitHub only mirrors this tap, with --force: a push made straight to it is erased by the next sync.
[[ $(git remote get-url origin) != *github.com* ]] || { echo "run this from the clone whose origin feeds the mirror, not the brew tap checkout" >&2; exit 1 }
[[ -z $(git status --porcelain -- "$cask") ]] || { echo "$cask has uncommitted changes" >&2; exit 1 }
sha=$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)
sed -i '' -E "s/^  version \".*\"/  version \"$version\"/; s/^  sha256 \".*\"/  sha256 \"$sha\"/" "$cask"
brew style "$cask"
# A cask committed by hand with the right numbers (a first release) leaves nothing to commit,
# and a rerun after a failed push has only the push left to do.
if [[ -n $(git status --porcelain -- "$cask") ]]; then
  git add "$cask"
  git commit -q -m "$token $version"
fi
if (( push )); then git push -q origin main; fi
echo "$token $version ($sha)"
