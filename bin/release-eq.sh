#!/usr/bin/env zsh
# Tag, build, sign and publish eq through publish-app.sh.
# Usage: bin/release-eq.sh <version>      (e.g. 0.1.0)
set -euo pipefail

src=${EQ_SRC:-/Volumes/SanDisk/projects/eq}
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
(( $# == 1 )) || { sed -n '2,3p' "$0" >&2; exit 2 }
version=$1
tag=v$version

[[ -d $src/.git ]] || { echo "no checkout at $src" >&2; exit 1 }
[[ -z $(git -C "$src" status --porcelain) ]] || { echo "$src has uncommitted changes" >&2; exit 1 }
[[ $(git -C "$src" branch --show-current) == main ]] || { echo "not on main" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] || { echo "main is not pushed to origin" >&2; exit 1 }
git -C "$src" rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "tag $tag already exists" >&2; exit 1 }

git -C "$src" tag -a "$tag" -m "eq $version"
git -C "$src" push -q origin "$tag"

"$src/scripts/build-app.sh" --identity "$identity"
"$src/scripts/smoke.sh" "$src/build/EQ.app/Contents/MacOS/eq"
exec "${0:a:h}/publish-app.sh" eq servitola/eq "$version" "$src/build/EQ.app" \
  --hardened --entitlements "$src/Resources/eq.entitlements" --tag "$tag"
