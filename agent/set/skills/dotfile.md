Dotfiles are configuration or marker files whose name begins with a dot and have no traditional file extension. They serve infrastructure roles (directory preservation, tool configuration, access control) rather than containing application logic.

## Inventory

| File | Purpose |
| ---- | ------- |
| `.keep` | Empty marker that forces git to track an otherwise-empty directory |
| `.gitignore` | Patterns for files git should not track |
| `.envrc` | direnv hook that activates the nix devShell on `cd` |
| `.markdownlint.jsonc` | markdownlint configuration |
| `.yamllint.yml` | yamllint configuration |
| `.coverage-allowlist` | Paths exempt from the test-coverage lefthook check |
| `.tdd-order-baseline` | Commit SHA baseline for the TDD-order lefthook check |
| `.nix-embedded-shell-allowlist` | Paths exempt from the nix-embedded-shell lefthook check |

## Conventions

- Use `.keep` (not `.gitkeep`) as the directory-preservation marker.
- `.keep` files are always empty -- no content, no comments.
- When a directory that previously needed `.keep` gains real content, remove the `.keep` file.
