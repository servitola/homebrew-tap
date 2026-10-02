#!/usr/bin/env zsh
# POST_RELEASE_HOOK of scripts/community/release.sh in the AltTab repository, which passes the version alone.
# Usage: bin/bump-alt-tab-community.sh <version> [--no-push]
set -euo pipefail

version=${1:?usage: bin/bump-alt-tab-community.sh <version> [--no-push]}
exec "${0:a:h}/bump-cask.sh" alt-tab-community "$version" \
  "https://github.com/servitola/alt-tab-community/releases/download/community-$version/AltTab-$version.zip" "${@:2}"
