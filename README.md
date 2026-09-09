<div align="center">

<img src=".github/banner.jpg" alt="" width="100%">

# homebrew-tap

My own macOS builds — forks I maintain and apps I wrote — as Homebrew casks.

[![brew test-bot](https://github.com/servitola/homebrew-tap/actions/workflows/tests.yml/badge.svg)](https://github.com/servitola/homebrew-tap/actions/workflows/tests.yml)
[![casks](https://img.shields.io/badge/casks-7-brightgreen)](Casks)
[![licence](https://img.shields.io/badge/licence-BSD--2--Clause-blue)](LICENSE)

</div>

```bash
brew tap servitola/tap
brew install servitola/tap/<token>
```

Homebrew 6 trusts a third-party item only when it is named in full, so install and
upgrade with the `servitola/tap/` prefix. `brew trust --cask servitola/tap/<token>`
buys the short name; `brew trust --tap servitola/tap` trusts everything here, now and
in future — which is a promise about code that has not been written yet.

## Casks

| Token | What | Built | Source |
| --- | --- | --- | --- |
| `transmission` | Transmission with a native Liquid Glass UI (macOS 26+) | nightly | [transmission](https://github.com/servitola/transmission) |
| `forkgram` | Telegram Desktop (Forkgram) + personal patches | nightly | [telegram-desktop](https://github.com/servitola/telegram-desktop) 🔒 |
| `zap-terminal` | Zap, the open-source Warp fork | nightly | [zap-terminal](https://github.com/servitola/zap-terminal) |
| `voiceink` | VoiceInk (voice to text) + personal patches | nightly | [VoiceInk](https://github.com/servitola/VoiceInk) |
| `zen` | Zen Browser from source, auto-update off | weekly | [zen-browser](https://github.com/servitola/zen-browser) |
| `claude-counter` | Menu-bar indicator of Claude.ai usage | on demand | [claude_counter](https://github.com/servitola/claude_counter) |
| `glasswings` | Notification-banner daemon + `glasswings-send` | on demand | [glasswings](https://github.com/servitola/glasswings) 🔒 |

Three tokens (`transmission`, `voiceink`, `zen`) are the same as in homebrew/cask
on purpose — same app, my build. In a Brewfile write `cask "servitola/tap/zen"`: a
bare token pulls the core cask over my build. `zap-terminal` is not `zap`, which is
OWASP ZAP upstream.

🔒 = the release lives in a private repository. Those casks resolve the asset
through the GitHub API using the local `gh` login (or `HOMEBREW_GITHUB_API_TOKEN`),
so they need `gh auth login` on the machine.

Nothing here is notarized, so every cask drops the quarantine attribute after
install — what `--no-quarantine` does. Signing is Developer ID, except `voiceink`
(self-signed identity its TCC grants are pinned to) and `zen` (ad-hoc).

## Layout

```
Casks/       one cask per app
lib/         Ruby shared by casks, reached with require_relative
bin/         the publisher and the two on-demand release scripts
.github/     brew test-bot on every push to main
```

## Publishing

`bin/publish-app.sh <token> <owner/repo> <version> <App.app>` signs the bundle,
zips it, cuts GitHub release `v<version>`, rewrites `version`/`sha256` in the
cask, commits and pushes. Options: `--identity`, `--entitlements`, `--hardened`,
`--strip`, `--tag`, `--target`, `--no-push`.

Push goes to gitea; its mirror carries the commit to GitHub, which is never
pushed directly. The release tag must point at a commit the source repo already
has on GitHub.

| App | Trigger |
| --- | --- |
| Claude Counter | `bin/release-claude-counter.sh <version>` |
| Glasswings | `bin/release-glasswings.sh <version>` |
| Transmission, Forkgram, Zap, VoiceInk, Zen | their `dotfiles/cron/scripts/*-sync.sh` job, after a green build; `bin/release-transmission.sh` builds Transmission on demand |

The two script-driven tags (Claude Counter, Glasswings) are pushed to gitea, not
GitHub: the mirror runs `--mirror --force` and would delete a tag made upstream.
The same force-mirror is why CI here only reads: a merged pull request or a
Dependabot bump on GitHub would be erased by the next sync, so the action pins in
`.github/workflows/tests.yml` are bumped by hand.

## Adding a cask

Write `Casks/<token>.rb` following the [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
stanza order, point `url` at a GitHub release asset, then:

```bash
brew style Casks lib
brew audit --cask --online --strict servitola/tap/<token>
brew livecheck --cask servitola/tap/<token>
```

Conventions worth keeping: `postflight_steps` rather than the deprecated Ruby
`postflight`, `uninstall quit:` for anything that may be running, a `livecheck`
block, and a `zap trash:` list covering the app's own `~/Library` paths.

Install steps run in a sandbox, which shapes what a cask can do at install time:
`write_file` reaches `~` through `base: :home`, but `{{home}}` is not expanded
inside step content (`{{user}}`, `{{appdir}}` and `{{version}}` are), and
`launchctl bootstrap`/`load` answer `5: Input/output error` there while the same
plist loads by hand — see the comment in `Casks/glasswings.rb`.
