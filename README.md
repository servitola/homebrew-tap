# homebrew-tap

My own macOS builds — forks I maintain and apps I wrote — as Homebrew casks.

```bash
brew tap servitola/tap
brew install servitola/tap/<token>
```

## Casks

| Token | What | Built | Source |
| --- | --- | --- | --- |
| `transmission` | Transmission with a native Liquid Glass UI (macOS 26+) | on demand | [transmission](https://github.com/servitola/transmission) |
| `forkgram` | Telegram Desktop (Forkgram) + personal patches | nightly | [telegram-desktop](https://github.com/servitola/telegram-desktop) 🔒 |
| `zap-terminal` | Zap, the open-source Warp fork | nightly | [zap-terminal](https://github.com/servitola/zap-terminal) |
| `voiceink` | VoiceInk (voice to text) + personal patches | nightly | [VoiceInk](https://github.com/servitola/VoiceInk) |
| `zen` | Zen Browser from source, auto-update off | weekly | [zen-browser](https://github.com/servitola/zen-browser) |
| `claude-counter` | Menu-bar indicator of Claude.ai usage | on demand | [claude_counter](https://github.com/servitola/claude_counter) |
| `glasswings` | Notification-banner daemon + `glasswings-send` | on demand | [glasswings](https://github.com/servitola/glasswings) 🔒 |

Three tokens (`transmission`, `voiceink`, `zen`) are the same as in homebrew/cask
on purpose — same app, my build. Install and upgrade them fully qualified, and in
a Brewfile write `cask "servitola/tap/zen"`: a bare token pulls the core cask over
my build. `zap-terminal` is not `zap`, which is OWASP ZAP upstream.

🔒 = the release lives in a private repository. Those casks resolve the asset
through the GitHub API using the local `gh` login (or `HOMEBREW_GITHUB_API_TOKEN`),
so they need `gh auth login` on the machine.

Nothing here is notarized, so every cask drops the quarantine attribute after
install — what `--no-quarantine` does. Signing is Developer ID, except `voiceink`
(self-signed identity its TCC grants are pinned to) and `zen` (ad-hoc).

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
| Transmission | `bin/release-transmission.sh [version]` |
| Claude Counter | `bin/release-claude-counter.sh <version>` |
| Glasswings | `bin/release-glasswings.sh <version>` |
| Forkgram, Zap, VoiceInk, Zen | their `dotfiles/cron/scripts/*-sync.sh` job, after a green build |

The two script-driven tags (Claude Counter, Glasswings) are pushed to gitea, not
GitHub: the mirror runs `--mirror --force` and would delete a tag made upstream.

## Adding a cask

Write `Casks/<token>.rb` following the [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
stanza order, point `url` at a GitHub release asset, then:

```bash
brew style --except-cops Lint/DuplicateMethods,Cask/InstallSteps Casks/<token>.rb
brew audit --cask --online servitola/tap/<token>
```

Conventions worth keeping: `postflight_steps` rather than the deprecated Ruby
`postflight` (only `glasswings` still needs the old form — see the cask),
`uninstall quit:` for anything that may be running, a `livecheck` block, and a
`zap trash:` list covering the app's own `~/Library` paths.
