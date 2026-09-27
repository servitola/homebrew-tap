#!/usr/bin/env zsh
# Build, sign and smoke eq, then tag it and publish through publish-app.sh; a failed build or
# smoke leaves no tag. The running com.servitola.eq agent is parked for the smoke and restored
# on exit, whether the release succeeds or not.
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
agent=gui/$UID/com.servitola.eq
plist=$HOME/Library/LaunchAgents/com.servitola.eq.plist
parked=0
trap 'rm -f "$notes"; (( parked )) && launchctl bootstrap gui/$UID "$plist" 2>/dev/null || true' EXIT
awk -v v="$version" '
  /^## / { on = index($0, "## " v " ") == 1 }
  on && !/^## / { print }
' "$src/CHANGELOG.md" | sed -e '1{/^$/d;}' > "$notes"
[[ -s $notes ]] || { echo "CHANGELOG.md has no section for $version" >&2; exit 1 }

APP_VERSION=$version "$src/scripts/build-app.sh" --identity "$identity"
# The smoke refuses to start next to a live daemon: two taps on one device would stack.
if launchctl print "$agent" >/dev/null 2>&1; then
  launchctl bootout "$agent"; parked=1
  for _ in {1..25}; do pgrep -f 'MacOS/eq daemon' >/dev/null || break; sleep 0.2; done
fi
EQ_SMOKE_TONE=1 "$src/scripts/smoke.sh" "$src/build/EQ.app/Contents/MacOS/eq"

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

"${0:a:h}/publish-app.sh" eq servitola/eq "$version" "$src/build/EQ.app" \
  --hardened --entitlements "$src/Resources/eq.entitlements" --tag "$tag" --notes-file "$notes"
