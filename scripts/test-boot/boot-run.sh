#!/usr/bin/env bash
# Start the guest binary cache (nix-serve) and run the boot QEMU launch
# script, returning QEMU's exit code. Runs inside the detached tmux
# session spawned by qemu-remote-tmux.sh; nix-serve and qemu are provided
# by that session's nix-shell.
#
# Self-locating: synced to <work-dir>/scripts/, so run-qemu.sh (written by
# qemu-cmd.sh) sits one level up at <work-dir>/run-qemu.sh. Takes no args
# because the tmux runner invokes it bare.

set -uo pipefail

work_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Free any stale :5000 binding from a prior boot, then start the cache.
fuser -k 5000/tcp 2>/dev/null || true
nix-serve -p 5000 &
serve_pid=$!

bash "$work_dir/run-qemu.sh"
rc=$?

kill "$serve_pid" 2>/dev/null || true
exit "$rc"
