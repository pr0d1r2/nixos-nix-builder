# RTK (Rust Token Killer)

RTK is a token-optimized CLI proxy that reduces context window usage by
60-90% on common dev operations. CLAUDE.md has the full command reference.

## Project-specific overrides

### git push

Use `rtk proxy git push` for pushes. Plain `rtk git push` strips lefthook
failure output (lines starting with `🥊`) and `[FAILED]` systemd service
lines, making push failures undebuggable. `rtk proxy` bypasses all filters.

### Per-repo filters

`.rtk/filters.toml` exists in the repo for per-project filter customization,
but RTK's built-in filters cannot be overridden via this file today. Use
`rtk proxy <cmd>` when a built-in filter hides output you need.

## When to use rtk proxy

- `git push` (pre-push hooks produce critical output)
- Any command where you need the full, unfiltered output for debugging
- When RTK's filtering hides an error you need to diagnose

## When NOT to use rtk

- The Bash tool description says to prefer dedicated tools (Read, Grep, Glob,
  Edit) over shell commands. RTK wraps shell commands, so the same rule
  applies: use dedicated tools first, RTK-wrapped shell commands only when
  the dedicated tool cannot do the job.
