#!/usr/bin/env zsh
# Build the fork's macOS client and publish it through publish-app.sh.
# Usage: bin/release-transmission.sh [version]   (default: 4.2.0-dev.<today>)
set -euo pipefail

src=${TRANSMISSION_SRC:-/Volumes/SanDisk/projects/transmission}
version=${1:-4.2.0-dev.$(date +%Y%m%d)}

[[ -d $src ]] || { echo "fork not found at $src (SanDisk mounted?)" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] ||
  { echo "HEAD is not origin/main: push the fork first, the release tag points at main" >&2; exit 1 }

cmake --build "$src/build" -t transmission-mac
exec "${0:a:h}/publish-app.sh" transmission servitola/transmission "$version" "$src/build/macosx/Transmission.app"
