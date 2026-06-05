Every file type tracked in git must have an assigned linter in lefthook.yml (both pre-commit and pre-push). When adding a new file type to the repo, add its linter before committing.

## Current coverage

| Extension | Linter | Notes |
| --------- | ------ | ----- |
| `.nix` | statix, deadnix, nixfmt | Three complementary checks |
| `.sh` | shellcheck, shfmt | Correctness + format |
| `.bats` | shellcheck, `bats -c` | Correctness + parse-only validation |
| `.md` | markdownlint | Config in `.markdownlint.jsonc` |
| `.yml` | yamllint | Config in `.yamllint.yml` |
| `.toml` | taplo | TOML format checker |
| `.json` | — | Validated by consuming tools |
| `.jsonc` | — | Validated by markdownlint itself |
| `.lock` | — | Generated file, no lint needed |
| `.keep` | — | Empty directory-preservation marker |
| `.gitignore` | — | Trivial format, no lint needed |
| `.envrc` | — | Sourced by direnv |
| `.dic` | — | Word list, no lint needed |
| `.exp` | — | Expect scripts, validated by tcl-syntax |
| `.tcl` | — | Tcl libraries, validated by tcl-syntax |
| `.editorconfig` | — | INI-like format, validated by editors |
| `.gitattributes` | — | Simple key-value format |
| `.coverage-allowlist` | — | Line-per-path allowlist, no lint needed |
| `.nix-embedded-shell-allowlist` | — | Line-per-path allowlist, no lint needed |
| `.shell-functions-allowlist` | — | Line-per-path allowlist, no lint needed |
| `.tdd-order-baseline` | — | Single SHA marker, no lint needed |
| `justfile` | — | `just --fmt --check` available but unstable |
| `LICENSE` | — | Legal text, no lint needed |
| `fstype` | — | User config value, no lint needed |
| `keymap` | — | User config value, no lint needed |
| `locale` | — | User config value, no lint needed |
| `timezone` | — | User config value, no lint needed |

## Cross-cutting checks

| Check | Scope | Notes |
| ----- | ----- | ----- |
| `unicode-lint` | all text files | Detects invalid UTF-8 |

## Adding a new linter

1. Add the tool to both devShells in `flake.nix`
2. Add a command to both `pre-commit` and `pre-push` in `lefthook.yml`
3. Use `glob` to scope to the right file extensions
4. Fix any existing violations before committing
5. Update this table
