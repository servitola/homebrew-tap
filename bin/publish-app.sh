#!/usr/bin/env zsh
# Sign an .app, attach it to a GitHub release, bump the cask, commit, push.
# Usage: bin/publish-app.sh <cask-token> <owner/repo> <version> <path/to/App.app>
#          [--identity "<name or sha1>"] [--entitlements plist] [--hardened] [--strip]
#          [--tag v<version>] [--target main] [--no-push]
# The tag is created on --target, so that ref on GitHub must already be the commit that
# was built. Asset name: <App>-<version>.zip.
set -euo pipefail

tap=${0:a:h:h}
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
entitlements= hardened=0 strip=0 tag= target=main push=1
(( $# >= 4 )) || { sed -n '2,7p' "$0" >&2; exit 2 }
token=$1 gh_repo=$2 version=$3 app=${4:a}; shift 4
while (( $# )); do
  case $1 in
    --identity) identity=$2; shift 2 ;;
    --entitlements) entitlements=$2; shift 2 ;;
    --hardened) hardened=1; shift ;;
    --strip) strip=1; shift ;;
    --tag) tag=$2; shift 2 ;;
    --target) target=$2; shift 2 ;;
    --no-push) push=0; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
: ${tag:=v$version}
cask=Casks/$token.rb
name=${app:t:r}
zip=$name-$version.zip

[[ -d $app ]] || { echo "no app bundle at $app" >&2; exit 1 }
[[ -f $tap/$cask ]] || { echo "no cask $tap/$cask" >&2; exit 1 }
[[ -z $entitlements || -f $entitlements ]] || { echo "no entitlements file $entitlements" >&2; exit 1 }
git -C "$tap" diff --quiet -- "$cask" || { echo "$cask has uncommitted changes" >&2; exit 1 }
# Not `-v`: a self-signed identity is listed as CSSMERR_TP_NOT_TRUSTED and still signs.
# "-" is ad-hoc (zen: a Firefox bundle whose helpers are not set up for a real identity).
[[ $identity == - ]] || security find-identity -p codesigning | grep -q -- "$identity" ||
  { echo "signing identity missing: $identity" >&2; exit 1 }
gh release view "$tag" -R "$gh_repo" >/dev/null 2>&1 && { echo "release $tag already exists in $gh_repo" >&2; exit 1 }

work=$(mktemp -d)
committed=0
cleanup() {
  rm -rf "$work"
  (( committed )) || git -C "$tap" checkout -q -- "$cask"
}
trap cleanup EXIT

ditto "$app" "$work/$name.app"
if (( strip )); then
  exe=$(defaults read "$work/$name.app/Contents/Info.plist" CFBundleExecutable)
  # -x drops only local symbols: it is what takes an unstripped Xcode build from 1.6 GB
  # to 0.5 GB, and it cannot break dlsym on exported symbols the way a full strip can.
  strip -x "$work/$name.app/Contents/MacOS/$exe"
fi
# --deep is deprecated but is still what re-signs nested frameworks, helpers and plugins.
# Apple's timestamp service refuses a self-signed identity, and those are exactly the
# identities an app's TCC grants may be pinned to (VoiceInk), so the timestamp follows
# the identity.
sign=(codesign --force --deep --sign "$identity")
[[ $identity == *"Developer ID"* ]] && sign+=(--timestamp) || sign+=(--timestamp=none)
(( hardened )) && sign+=(--options runtime)
if [[ -n $entitlements ]]; then
  sign+=(--entitlements "$entitlements")
else
  sign+=(--preserve-metadata=entitlements)
fi
"${sign[@]}" "$work/$name.app"
codesign --verify --deep --strict "$work/$name.app"
(cd "$work" && ditto -c -k --sequesterRsrc --keepParent "$name.app" "$zip")
sha=$(shasum -a 256 "$work/$zip" | cut -d' ' -f1)

sed -i '' -e "s|^  version \".*\"|  version \"$version\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$tap/$cask"
grep -q "version \"$version\"" "$tap/$cask" && grep -q "sha256 \"$sha\"" "$tap/$cask" || { echo "cask bump failed" >&2; exit 1 }
brew style "$tap/$cask"

gh release create "$tag" -R "$gh_repo" --target "$target" --title "$name $version" \
  --notes "Built from $gh_repo@$target, signed with \"$identity\", not notarized. Install: brew install servitola/tap/$token" \
  "$work/$zip"

git -C "$tap" add "$cask"
git -C "$tap" commit -q -m "$token $version"
committed=1
if (( push )); then
  git -C "$tap" push -q
  # brew reads the tap from GitHub, which the gitea push mirror fills a few seconds later;
  # a brew install right after this call must not race it.
  head=$(git -C "$tap" rev-parse HEAD)
  for _ in {1..12}; do
    [[ $(gh api repos/servitola/homebrew-tap/commits/main -q .sha 2>/dev/null) == "$head" ]] && break
    sleep 5
  done
  git -C "$(brew --repository servitola/tap)" pull -q --ff-only || true
fi
echo "published $gh_repo $tag; cask $token -> $version"
