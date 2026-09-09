#!/usr/bin/env zsh
# Build the fork's macOS client and publish it — the same steps the nightly
# dotfiles/cron/scripts/transmission-sync.sh runs, for a build on demand.
# Usage: bin/release-transmission.sh [version]
set -euo pipefail

src=${TRANSMISSION_SRC:-/Volumes/SanDisk/projects/transmission}
[[ -d $src ]] || { echo "fork not found at $src (SanDisk mounted?)" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] ||
  { echo "HEAD is not origin/main: push the fork first, the release tag points at main" >&2; exit 1 }

if (( $# )); then
  version=$1
else
  version=$(awk -F'"' '/^set\(TR_VERSION_MAJOR/{a=$2} /^set\(TR_VERSION_MINOR/{b=$2} /^set\(TR_VERSION_PATCH/{c=$2} END{print a"."b"."c}' "$src/CMakeLists.txt")
  grep -q '^set(TR_VERSION_DEV TRUE)' "$src/CMakeLists.txt" && version="$version-dev"
  version="$version.$(date +%Y%m%d).$(git -C "$src" rev-parse --short=7 HEAD)"
fi

cmake --build "$src/build" -t transmission-mac
exec "${0:a:h}/publish-app.sh" transmission servitola/transmission "$version" "$src/build/macosx/Transmission.app"
