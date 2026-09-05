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

The token is the same as the core cask on purpose: it is the same app, and
`brew upgrade` resolves the installed cask by its tap. Uninstall the core
cask before installing this one, otherwise Homebrew refuses to overwrite
`/Applications/Transmission.app`:

```bash
brew uninstall --cask transmission
brew install servitola/tap/transmission
```

Builds are signed with Developer ID but not notarized. The cask strips the
quarantine attribute after install, which is what `--no-quarantine` does.

## Publishing a new Transmission build

```bash
bin/release-transmission.sh            # version defaults to 4.2.0-dev.<today>
git push
```

The script builds the Cocoa client from the fork on SanDisk, signs it, creates
a GitHub release with the zip, rewrites `version` and `sha256` in the cask and
commits. Pushing to gitea publishes: the repository is a gitea push mirror to
GitHub, so GitHub is never pushed directly.

## Adding a cask or formula

Casks go to `Casks/<token>.rb`, formulae to `Formula/<name>.rb`. Point `url` at
a GitHub release asset of the source repository and fill `sha256` from
`shasum -a 256`. Check with `brew style Casks/<token>.rb` and
`brew audit --cask --online servitola/tap/<token>`, then commit and push.
