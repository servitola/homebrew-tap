#!/usr/bin/env zsh
# Tag, build and publish Claude Counter through publish-app.sh.
# Usage: bin/release-claude-counter.sh <version>      (e.g. 1.2.0)
# The tag goes to gitea; the push mirror carries it to GitHub, where the release is made.
set -euo pipefail

src=${CLAUDE_COUNTER_SRC:-$HOME/projects/services/claude_counter}
identity="Developer ID Application: Vladislav Konovalov (NZNV266K59)"
(( $# == 1 )) || { sed -n '2,4p' "$0" >&2; exit 2 }
version=$1
tag=v$version

[[ -d $src/.git ]] || { echo "no checkout at $src" >&2; exit 1 }
[[ -z $(git -C "$src" status --porcelain) ]] || { echo "$src has uncommitted changes" >&2; exit 1 }
[[ $(git -C "$src" branch --show-current) == main ]] || { echo "not on main" >&2; exit 1 }
git -C "$src" fetch -q origin
[[ $(git -C "$src" rev-parse HEAD) == $(git -C "$src" rev-parse origin/main) ]] || { echo "main is not pushed to origin" >&2; exit 1 }
git -C "$src" rev-parse -q --verify "refs/tags/$tag" >/dev/null && { echo "tag $tag already exists" >&2; exit 1 }

git -C "$src" tag -a "$tag" -m "Claude Counter $version"
git -C "$src" push -q origin "$tag"
head=$(git -C "$src" rev-parse "$tag^{commit}")
for _ in {1..12}; do
  [[ $(gh api "repos/servitola/claude_counter/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] && break
  sleep 5
done
[[ $(gh api "repos/servitola/claude_counter/commits/$tag" -q .sha 2>/dev/null) == "$head" ]] ||
  { echo "GitHub did not receive $tag from the gitea mirror" >&2; exit 1 }

# build-app.sh derives the version from the newest tag, so the tag must exist first.
CODESIGN_IDENTITY=$identity "$src/scripts/build-app.sh"
exec "${0:a:h}/publish-app.sh" claude-counter servitola/claude_counter "$version" "$src/App/.build/ClaudeCounter.app" --tag "$tag"
