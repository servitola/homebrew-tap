#!/usr/bin/env zsh
# Tag, build and publish Glasswings through publish-app.sh.
# Usage: bin/release-glasswings.sh <version>      (e.g. 0.4)
# The tag goes to gitea; the push mirror carries it to GitHub, where the release is made.
set -euo pipefail

src=${GLASSWINGS_SRC:-$HOME/projects/glasswings}
gh_repo=servitola/glasswings
(( $# == 1 )) || { sed -n '2,4p' "$0" >&2; exit 2 }
version=$1
tag=v$version

[[ -d $src/.git ]] || { echo "no checkout at $src" >&2; exit 1 }
[[ -z $(git -C "$src" status --porcelain) ]] || { echo "$src has uncommitted changes" >&2; exit 1 }
[[ $(git -C "$src" branch --show-current) == main ]] || { echo "not on main" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] || { echo "main is not pushed to origin" >&2; exit 1 }
git -C "$src" rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "tag $tag already exists" >&2; exit 1 }

git -C "$src" tag -a "$tag" -m "Glasswings $version"
git -C "$src" push -q origin "$tag"
head=$(git -C "$src" rev-parse "$tag^{commit}")
for _ in {1..12}; do
  [[ $(gh api "repos/$gh_repo/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] && break
  sleep 5
done
[[ $(gh api "repos/$gh_repo/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] ||
  { echo "GitHub did not receive $tag from the gitea mirror" >&2; exit 1 }

# build-app.sh derives the version from the newest tag, so the tag must exist first. It
# also signs and "installs" into the path given: a staging dir here, never /Applications.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
bash "$src/scripts/build-app.sh" "$src" "$work/Glasswings.app"
"${0:a:h}/publish-app.sh" glasswings "$gh_repo" "$version" "$work/Glasswings.app" --tag "$tag"
