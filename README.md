# homebrew-tap

Personal Homebrew tap: my forks and builds, published as casks and formulae.

```bash
brew tap servitola/tap
brew install servitola/tap/transmission
```

## Casks

| Token | What | Source |
| --- | --- | --- |
| `transmission` | Transmission with native Liquid Glass UI (macOS 26+) | [servitola/transmission](https://github.com/servitola/transmission) |
| `zap-terminal` | Zap terminal (open-source Warp fork), nightly build | [servitola/zap-terminal](https://github.com/servitola/zap-terminal) |

`transmission` keeps the core cask's token on purpose: it is the same app, and
`brew upgrade` resolves the installed cask by its tap. Uninstall the core
cask before installing this one, otherwise Homebrew refuses to overwrite
`/Applications/Transmission.app`:

```bash
brew uninstall --cask transmission
brew install servitola/tap/transmission
```

`zap-terminal` is not `zap` because that token is OWASP ZAP in homebrew/cask.

Builds are signed with Developer ID but not notarized. Each cask strips the
quarantine attribute after install, which is what `--no-quarantine` does.

## Publishing a build

`bin/publish-app.sh <token> <owner/repo> <version> <App.app> [--entitlements plist]`
signs the bundle, zips it, creates GitHub release `v<version>` on the repo's
`main` with the zip attached, rewrites `version` and `sha256` in
`Casks/<token>.rb`, commits and pushes. Pushing to gitea is what publishes:
this repository is a gitea push mirror to GitHub, GitHub is never pushed
directly. The release tag points at `main`, so `main` on GitHub must already be
the commit that was built.

- Transmission: `bin/release-transmission.sh [version]` builds the Cocoa client
  from the fork on SanDisk and calls `publish-app.sh` (version defaults to
  `4.2.0-dev.<today>`).
- Zap: the nightly `dotfiles/cron/scripts/zap-sync.sh` builds, publishes
  `0.1.0-<date>.<sha>` with the TCC entitlements and installs it with
  `brew upgrade`. See `dotfiles/cron/cron_jobs/fork-sync/zap.private.cron`.

## Adding a cask or formula

Casks go to `Casks/<token>.rb`, formulae to `Formula/<name>.rb`. Point `url` at
a GitHub release asset of the source repository and fill `sha256` from
`shasum -a 256`. Check with `brew style Casks/<token>.rb` and
`brew audit --cask --online servitola/tap/<token>`, then commit and push.
