Every user-facing operation should be a single `just` command.
The user should never need to know underlying tools, flags, paths,
or multi-step sequences. Minimal knowledge to interact:

    just              # list everything available
    just <cmd>        # do the thing

## Principles

- **Zero setup.** Entering the repo activates everything via
  direnv. No manual installs, no "run X first."
- **One command, one outcome.** `just build` builds. `just burn`
  burns. No manual pre-steps.
- **Self-documenting.** `just --list` shows all commands with
  descriptions. Copy-paste from the listing works.
- **No tool leakage.** User never runs nix, qemu, ssh, rsync,
  or expect directly. Just wraps all of them.
- **Fail with guidance.** When prerequisites are missing, print
  what to do — not a raw tool error.

## Anti-patterns

- Documenting raw commands in README instead of wrapping in just
- Requiring env vars the user must set manually
- Multi-step instructions ("first do A, then B, then C")
- Silent failures — always tell user what went wrong and how to fix
