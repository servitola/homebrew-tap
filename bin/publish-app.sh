#!/usr/bin/env zsh
# Sign an .app with Developer ID, attach it to a GitHub release, bump the cask, commit, push.
# Usage: bin/publish-app.sh <cask-token> <owner/repo> <version> <path/to/App.app>
#                           [--entitlements plist] [--no-push]
# The tag is v<version> on the repo's main, so main on GitHub must already be the commit
# that was built. Asset name: <App>-<version>.zip.
set -euo pipefail

tap=${0:a:h:h}
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
entitlements= push=1
(( $# >= 4 )) || { sed -n '2,5p' "$0" >&2; exit 2 }
token=$1 gh_repo=$2 version=$3 app=${4:a}; shift 4
while (( $# )); do
  case $1 in
    --entitlements) entitlements=$2; shift 2 ;;
    --no-push) push=0; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
cask=Casks/$token.rb
name=${app:t:r}
tag=v$version
zip=$name-$version.zip

[[ -d $app ]] || { echo "no app bundle at $app" >&2; exit 1 }
[[ -f $tap/$cask ]] || { echo "no cask $tap/$cask" >&2; exit 1 }
[[ -z $entitlements || -f $entitlements ]] || { echo "no entitlements file $entitlements" >&2; exit 1 }
git -C "$tap" diff --quiet -- "$cask" || { echo "$cask has uncommitted changes" >&2; exit 1 }
security find-identity -v -p codesigning | grep -q "$identity" || { echo "signing identity missing: $identity" >&2; exit 1 }
gh release view "$tag" -R "$gh_repo" >/dev/null 2>&1 && { echo "release $tag already exists in $gh_repo" >&2; exit 1 }

work=$(mktemp -d)
committed=0
cleanup() {
  rm -rf "$work"
  (( committed )) || git -C "$tap" checkout -q -- "$cask"
}
trap cleanup EXIT

ditto "$app" "$work/$name.app"
# An app that holds TCC grants (a terminal: Full Disk Access, Automation, mic) needs the
# hardened runtime and its entitlements re-applied on every re-sign. --deep is deprecated
# but is still what re-signs nested helpers and plugins.
if [[ -n $entitlements ]]; then
  codesign --force --deep --options runtime --entitlements "$entitlements" --timestamp --sign "$identity" "$work/$name.app"
else
  codesign --force --timestamp --sign "$identity" "$work/$name.app"
fi
codesign --verify --deep --strict "$work/$name.app"
(cd "$work" && ditto -c -k --sequesterRsrc --keepParent "$name.app" "$zip")
sha=$(shasum -a 256 "$work/$zip" | cut -d' ' -f1)

sed -i '' -e "s|^  version \".*\"|  version \"$version\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$tap/$cask"
grep -q "version \"$version\"" "$tap/$cask" && grep -q "sha256 \"$sha\"" "$tap/$cask" || { echo "cask bump failed" >&2; exit 1 }
brew style "$tap/$cask"

gh release create "$tag" -R "$gh_repo" --target main --title "$name $version" \
  --notes "Built from $gh_repo@main, signed with Developer ID, not notarized. Install: brew install servitola/tap/$token" \
  "$work/$zip"

git -C "$tap" add "$cask"
git -C "$tap" commit -q -m "$token $version"
committed=1
(( push )) && git -C "$tap" push -q
echo "published $gh_repo $tag; cask $token -> $version"
