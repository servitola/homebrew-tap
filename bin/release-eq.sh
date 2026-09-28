#!/usr/bin/env zsh
# Build, sign and smoke eq, then tag it and publish through publish-app.sh; a failed build or
# smoke leaves no tag. Whichever eq daemon job is loaded is booted out for the smoke and restored
# on exit, whether the release succeeds or not: the legacy com.servitola.eq through launchctl
# bootstrap of the plist it was loaded from, the bundled com.servitola.eq.daemon through the
# installed eq agent install (an SMAppService job has no plist path to bootstrap from). The login
# item stays registered while parked, and an eq command leaves a registered-but-unloaded item
# alone, so nothing restarts the daemon mid-smoke.
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
# publish-app.sh refuses a dirty cask, and by then the tag is already pushed.
git -C "${0:a:h:h}" diff --quiet -- Casks/eq.rb || { echo "Casks/eq.rb has uncommitted changes" >&2; exit 1 }

notes=$(mktemp)
legacy=com.servitola.eq
bundled=com.servitola.eq.daemon
plist=$HOME/Library/LaunchAgents/$legacy.plist
installed=/Applications/EQ.app/Contents/MacOS/eq
parked=()
restore() {
  local label
  for label in $parked; do
    case $label in
      $legacy) launchctl bootstrap gui/$UID "$plist" 2>/dev/null ||
                 echo "warning: could not restore $legacy — run: launchctl bootstrap gui/\$UID $plist" >&2 ;;
      $bundled) "$installed" agent install >/dev/null ||
                 echo "warning: could not restore $bundled — run: $installed agent install" >&2 ;;
    esac
  done
  parked=()
}
trap 'rm -f "$notes"; restore' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
awk -v v="$version" '
  /^## / { on = index($0, "## " v " ") == 1 }
  on && !/^## / { print }
' "$src/CHANGELOG.md" | sed -e '1{/^$/d;}' > "$notes"
[[ -s $notes ]] || { echo "CHANGELOG.md has no section for $version" >&2; exit 1 }

APP_VERSION=$version "$src/scripts/build-app.sh" --identity "$identity"
# The smoke refuses to start next to a live daemon: two taps on one device would stack.
for label in $legacy $bundled; do
  job=$(launchctl print gui/$UID/$label 2>/dev/null) || continue
  if [[ $label == $legacy ]]; then
    # The plist it was loaded from, which need not be the one in ~/Library/LaunchAgents.
    loaded_from=${${(M)${(f)job}:#$'\t'path = /*}#*= }
    [[ -n $loaded_from ]] && plist=$loaded_from
  fi
  launchctl bootout gui/$UID/$label
  parked+=($label)
done
if (( $#parked )); then
  for _ in {1..25}; do pgrep -f 'MacOS/eq daemon' >/dev/null || break; sleep 0.2; done
fi
EQ_SMOKE_TONE=1 "$src/scripts/smoke.sh" "$src/build/EQ.app/Contents/MacOS/eq"
restore

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
