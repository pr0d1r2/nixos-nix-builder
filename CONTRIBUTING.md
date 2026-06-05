# Contributing

Thank you for your interest in contributing to nixos-nix-builder! We
welcome bug reports, feature suggestions, and pull requests from the
community.

## Getting started

1. Fork the repository and clone your fork.
2. Enter the development shell:
   ```bash
   nix develop
   ```
   This installs all tools, linters, and git hooks automatically via
   lefthook.
3. Create a feature branch from `main`.

## Development workflow

This project follows **Test-Driven Development**. For every change:

1. Write a failing test first (`tests/unit/`).
2. Commit the red test.
3. Implement the fix or feature.
4. Commit once the test passes.

Unit tests use [bats](https://github.com/bats-core/bats-core) and live
under `tests/unit/`, mirroring the source tree structure. Run them with:

```bash
bats tests/unit/
```

## Commit guidelines

- Keep commits small and focused -- one logical change per commit.
- Write a short, imperative subject line (50 characters or fewer).
- Update `CHANGELOG.md` under `## Unreleased` when your change is
  user-visible.

Lefthook pre-commit hooks run automatically and check formatting,
linting, spelling, and test coverage. Please ensure all hooks pass
before submitting your pull request.

## Pull requests

- Open your pull request against `main`.
- Describe what the change does and why.
- Link any related issues.
- Make sure CI passes (all lefthook checks run in GitHub Actions).

## Code style

- **Shell scripts**: formatted with `shfmt`, checked by `shellcheck`.
  No functions -- use separate scripts instead.
- **Nix files**: formatted with `nixfmt`, checked by `statix` and
  `deadnix`. No embedded shell -- extract to `.sh` files.
- **Justfile**: recipes ordered alphabetically after the default recipe.

## Reporting issues

If you find a bug or have a feature request, please open a GitHub issue.
Include steps to reproduce the problem and any relevant error output.

## License

By contributing, you agree that your contributions will be licensed
under the [MIT License](LICENSE).
