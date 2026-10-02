#!/usr/bin/env zsh
# Sign an .app, attach it to a GitHub release, bump the cask, commit, push.
# Usage: bin/publish-app.sh <cask-token> <owner/repo> <version> <path/to/App.app>
#          [--identity "<name or sha1>"] [--entitlements plist] [--hardened] [--strip]
#          [--tag v<version>] [--target main] [--no-push] [--notes-file path]
#          [--notarize <notarytool keychain profile>]
# The tag is created on --target, so that ref on GitHub must already be the commit that
# was built. Asset name: <App without spaces>-<version>.zip.
# --notarize implies --hardened and needs a Developer ID identity; the published zip then
# carries a stapled app that Gatekeeper opens without stripping quarantine.
set -euo pipefail

tap=${0:a:h:h}
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
entitlements= hardened=0 strip=0 tag= target=main push=1 notes_file= notary_profile=
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
    --notes-file) notes_file=$2; shift 2 ;;
    --notarize) notary_profile=$2; hardened=1; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ -z $notary_profile || $identity == *"Developer ID Application"* ]] ||
  { echo "--notarize needs a Developer ID Application identity, got: $identity" >&2; exit 1 }
: ${tag:=v$version}
cask=Casks/$token.rb
name=${app:t:r}
# GitHub turns spaces in an asset name into dots, so a cask url built from the app name
# would miss the asset ("Boring Notch.app" -> Boring.Notch-<v>.zip). Drop them up front.
zip=${name// /}-$version.zip

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
sign=(codesign --force --sign "$identity")
[[ $identity == *"Developer ID"* ]] && sign+=(--timestamp) || sign+=(--timestamp=none)
(( hardened )) && sign+=(--options runtime)
if (( hardened )); then
  # Inside-out instead of --deep: --deep stamps the app's entitlements onto every nested
  # helper (Sparkle's XPC services, Updater.app) and the notary service wants each nested
  # binary signed with the hardened runtime and a timestamp in its own right.
  contents=$work/$name.app/Contents
  for f in ${(f)"$(find "$contents" -type f \( -perm -u+x -o -name '*.dylib' -o -name '*.so' \) 2>/dev/null)"}; do
    [[ $(file -b "$f") == *Mach-O* ]] || continue
    "${sign[@]}" --preserve-metadata=entitlements "$f"
  done
  # -depth lists children before parents, so a framework's XPC service is sealed first.
  for b in ${(f)"$(find "$contents" -depth -type d \( -name '*.framework' -o -name '*.xpc' -o -name '*.app' -o -name '*.appex' \))"}; do
    "${sign[@]}" --preserve-metadata=entitlements "$b"
  done
else
  sign+=(--deep)
fi
if [[ -n $entitlements ]]; then
  sign+=(--entitlements "$entitlements")
else
  sign+=(--preserve-metadata=entitlements)
fi
"${sign[@]}" "$work/$name.app"
codesign --verify --deep --strict "$work/$name.app"

if [[ -n $notary_profile ]]; then
  (cd "$work" && ditto -c -k --keepParent "$name.app" notarize.zip)
  echo "notarizing $name $version (profile $notary_profile)…"
  submit=$(xcrun notarytool submit "$work/notarize.zip" --keychain-profile "$notary_profile" \
             --wait --timeout 1h --output-format json) || true
  verdict_status=$(jq -r '.status // empty' <<< "$submit" 2>/dev/null || true)
  if [[ $verdict_status != Accepted ]]; then
    echo "notarization failed (status: ${verdict_status:-none}): $submit" >&2
    id=$(jq -r '.id // empty' <<< "$submit" 2>/dev/null || true)
    [[ -n $id ]] && xcrun notarytool log "$id" --keychain-profile "$notary_profile" >&2 || true
    exit 1
  fi
  xcrun stapler staple "$work/$name.app"
  xcrun stapler validate "$work/$name.app"
  # Gatekeeper's own verdict, the one a quarantined download gets. Captured, not piped
  # into grep -q: an early grep exit kills the writer and pipefail turns a pass into 141.
  verdict=$(spctl -a -vv -t exec "$work/$name.app" 2>&1) || true
  echo "$verdict"
  [[ $verdict == *"source=Notarized Developer ID"* ]] ||
    { echo "spctl does not accept the stapled app as Notarized Developer ID" >&2; exit 1 }
  rm "$work/notarize.zip"
fi
(cd "$work" && ditto -c -k --sequesterRsrc --keepParent "$name.app" "$zip")
sha=$(shasum -a 256 "$work/$zip" | cut -d' ' -f1)

sed -i '' -e "s|^  version \".*\"|  version \"$version\"|" -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" "$tap/$cask"
grep -q "version \"$version\"" "$tap/$cask" && grep -q "sha256 \"$sha\"" "$tap/$cask" || { echo "cask bump failed" >&2; exit 1 }
brew style "$tap/$cask"

notarized="not notarized"
[[ -n $notary_profile ]] && notarized="notarized by Apple"
footer="Built from $gh_repo@$target, signed with \"$identity\", $notarized. Install: brew install servitola/tap/$token"
if [[ -n $notes_file ]]; then
  [[ -f $notes_file ]] || { echo "no notes file $notes_file" >&2; exit 1 }
  { cat "$notes_file"; echo; echo "$footer"; } > "$work/notes.md"
  notes=(--notes-file "$work/notes.md")
else
  notes=(--notes "$footer")
fi
gh release create "$tag" -R "$gh_repo" --target "$target" --title "$name $version" "${notes[@]}" "$work/$zip"

git -C "$tap" add "$cask"
git -C "$tap" commit -q -m "$token $version"
committed=1
if (( push )); then
  git -C "$tap" push -q
  # brew reads the tap from GitHub, which the push mirror fills a few seconds later;
  # a brew install right after this call must not race it.
  head=$(git -C "$tap" rev-parse HEAD)
  for _ in {1..12}; do
    [[ $(gh api repos/servitola/homebrew-tap/commits/main -q .sha 2>/dev/null) == "$head" ]] && break
    sleep 5
  done
  git -C "$(brew --repository servitola/tap)" pull -q --ff-only || true
fi
echo "published $gh_repo $tag; cask $token -> $version"
