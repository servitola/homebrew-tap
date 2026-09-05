#!/usr/bin/env zsh
# Build the fork's macOS client, sign, publish a GitHub release, bump the cask.
# Usage: bin/release-transmission.sh [version]   (default: 4.2.0-dev.<today>)
# Publishing is a push to gitea afterwards; the mirror carries it to GitHub.
set -euo pipefail

src=${TRANSMISSION_SRC:-/Volumes/SanDisk/projects/transmission}
tap=${0:a:h:h}
cask=$tap/Casks/transmission.rb
gh_repo=servitola/transmission
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
version=${1:-4.2.0-dev.$(date +%Y%m%d)}
tag=v$version
zip=Transmission-$version.zip

[[ -d $src ]] || { echo "fork not found at $src (SanDisk mounted?)" >&2; exit 1 }
security find-identity -v -p codesigning | grep -q "$identity" || { echo "signing identity missing: $identity" >&2; exit 1 }
gh release view "$tag" -R $gh_repo >/dev/null 2>&1 && { echo "release $tag already exists" >&2; exit 1 }

cmake --build "$src/build" -t transmission-mac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
ditto "$src/build/macosx/Transmission.app" "$work/Transmission.app"
codesign --force --sign "$identity" --timestamp "$work/Transmission.app"
codesign --verify --strict "$work/Transmission.app"
(cd "$work" && ditto -c -k --sequesterRsrc --keepParent Transmission.app "$zip")
sha=$(shasum -a 256 "$work/$zip" | cut -d' ' -f1)

commit=$(git -C "$src" rev-parse --short HEAD)
gh release create "$tag" -R $gh_repo --target main \
  --title "Transmission $version (Liquid Glass)" \
  --notes "macOS Cocoa client with native Liquid Glass (macOS 26+). Built from $commit, signed with Developer ID, not notarized. Install: brew install servitola/tap/transmission" \
  "$work/$zip"

sed -i '' -e "s|^  version \".*\"|  version \"$version\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$cask"
brew style "$cask"
git -C "$tap" add Casks/transmission.rb
git -C "$tap" commit -m "transmission $version" -m "Built from $gh_repo@$commit."
echo "done: $tag published, cask bumped and committed. Now: git -C $tap push"
