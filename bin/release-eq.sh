#!/usr/bin/env zsh
# Tag, build, sign and publish eq through publish-app.sh.
# Usage: bin/release-eq.sh <version>      (CalVer, e.g. 2026.09.27)
# The version must have its own "## <version> — <date>" section in the checkout's CHANGELOG.md;
# that section becomes the GitHub release notes.
set -euo pipefail

src=${EQ_SRC:-/Volumes/SanDisk/projects/eq}
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
(( $# == 1 )) || { sed -n '2,5p' "$0" >&2; exit 2 }
version=$1
tag=v$version

[[ -d $src/.git ]] || { echo "no checkout at $src" >&2; exit 1 }
[[ -z $(git -C "$src" status --porcelain) ]] || { echo "$src has uncommitted changes" >&2; exit 1 }
[[ $(git -C "$src" branch --show-current) == main ]] || { echo "not on main" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] || { echo "main is not pushed to origin" >&2; exit 1 }
git -C "$src" rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "tag $tag already exists" >&2; exit 1 }

notes=$(mktemp)
trap 'rm -f "$notes"' EXIT
awk -v v="$version" '
  /^## / { on = index($0, "## " v " ") == 1 }
  on && !/^## / { print }
' "$src/CHANGELOG.md" | sed -e '1{/^$/d;}' > "$notes"
[[ -s $notes ]] || { echo "CHANGELOG.md has no section for $version" >&2; exit 1 }

git -C "$src" tag -a "$tag" -m "eq $version"
git -C "$src" push -q origin "$tag"
# origin is gitea; its push mirror carries the tag to GitHub, where the release is made.
head=$(git -C "$src" rev-parse "$tag^{commit}")
for _ in {1..12}; do
  [[ $(gh api "repos/servitola/eq/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] && break
  sleep 5
done
[[ $(gh api "repos/servitola/eq/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] ||
  { echo "GitHub did not receive $tag from the mirror" >&2; exit 1 }

APP_VERSION=$version "$src/scripts/build-app.sh" --identity "$identity"
"$src/scripts/smoke.sh" "$src/build/EQ.app/Contents/MacOS/eq"
"${0:a:h}/publish-app.sh" eq servitola/eq "$version" "$src/build/EQ.app" \
  --hardened --entitlements "$src/Resources/eq.entitlements" --tag "$tag" --notes-file "$notes"
