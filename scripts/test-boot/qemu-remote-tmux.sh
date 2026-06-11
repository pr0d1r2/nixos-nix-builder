#!/usr/bin/env bash
# Run an already-staged builder script (which launches QEMU with
# -serial stdio) inside a DETACHED tmux session on the builder, so it
# survives mac<->builder ssh drops. Stream its serial console back to
# stdout with automatic reconnect, and hold the SSH port-forward the
# caller needs for in-guest health checks. Return the script's exit code.
#
# Why: previously QEMU ran under a single `ssh -t builder bash run-qemu.sh`.
# Any transient ssh drop SIGHUP'd that remote shell and killed QEMU
# mid-boot ("guest did not finish booting"). Detaching into tmux
# decouples QEMU's lifetime from the connection; the stream is a
# separate, resumable reader.
#
# Usage: qemu-remote-tmux.sh <builder> <session> <ssh_port> <remote_run_script> [extra_nix_pkgs]
#   builder            ssh target (e.g. root@nix-builder.local)
#   session            tmux session name + scoped-reset key (e.g.
#                      nix-builder-smoke-<sha>)
#   ssh_port           port to forward (-L) for the caller's health checks
#   remote_run_script  path on the builder to the run-qemu.sh generated
#                      there by qemu-cmd.sh; its serial console (stdout)
#                      is captured. Must end with QEMU exiting.
#   extra_nix_pkgs     extra nixpkgs on PATH alongside tmux+qemu, space-
#                      separated (e.g. "nix-serve" for the boot guest's
#                      binary cache). Optional.
#
# Reconnect is replay-from-top: on each (re)connect we `tail -n +1 -F`
# the whole serial log. Duplicates are safe -- expect matches milestones
# idempotently, so a replayed backlog just fast-forwards to the live tail.

set -uo pipefail

builder="${1:?usage: qemu-remote-tmux.sh <builder> <session> <ssh_port> <remote_run_script> [extra_nix_pkgs]}"
session="${2:?session required}"
ssh_port="${3:?ssh_port required}"
run_script="${4:?remote_run_script required}"
extra_pkgs="${5:-}"

# The run script lives on the builder (qemu-cmd.sh wrote it there). Fail
# loudly if it is missing rather than detaching an empty tmux session.
# shellcheck disable=SC2029  # run_script must expand locally into the remote test
if ! ssh -o ConnectTimeout=10 "$builder" "[ -f '$run_script' ]" 2>/dev/null; then
  echo "qemu-remote-tmux: remote run script not found on $builder: $run_script" >&2
  exit 2
fi

logfile="/tmp/${session}.serial.log"
rcfile="/tmp/${session}.rc"
# Dedicated tmux socket per session: a fresh server inherits this
# nix-shell's env (tmux on PATH) instead of attaching to a stale default
# server. The socket path carries the session name so a scoped reset can
# pkill it.
sock="/tmp/${session}.tmux.sock"

# Kill the detached guest on our own exit (normal completion or a signal
# from the caller's process-group kill) so we never leak a guest. The
# session string is in the tmux socket path and QEMU's drive paths, so a
# single pkill -f reaps both. A network drop does NOT trigger this -- we
# stay alive reconnecting and QEMU keeps running.
# shellcheck disable=SC2064  # expand session/builder now, not at trap time
trap "ssh -o ConnectTimeout=5 '$builder' \"pkill -f '$session' 2>/dev/null; rm -f '$sock' '$logfile' '$rcfile'\" >/dev/null 2>&1 || true" EXIT

# Start the run script detached in a fresh tmux session under a nix-shell
# that provides tmux (qemu is launched by absolute path inside the run
# script). A stale same-name session is torn down first so new-session
# never collides. This start happens once -- the streaming loop reconnects
# on drops without re-running it, so the live log is never wiped mid-boot.
# shellcheck disable=SC2029,SC2086  # all expand locally; extra_pkgs is intentionally word-split
ssh -o ConnectTimeout=10 "$builder" "rm -f '$logfile' '$rcfile'; nix-shell -p tmux qemu $extra_pkgs --run \"tmux -S '$sock' kill-session -t '$session' 2>/dev/null || true; tmux -S '$sock' new-session -d -x 1000 -y 50 -s '$session' 'bash $run_script; echo \\\$? > $rcfile'; tmux -S '$sock' pipe-pane -t '$session' -o 'cat >> $logfile'\""

# Stream with reconnect until the guest exits (rc file appears).
rc=1
while true; do
  if ssh -o ConnectTimeout=5 "$builder" "[ -f '$rcfile' ]" 2>/dev/null; then
    # Flush any tail we missed, then read the exit code and stop.
    ssh -o ConnectTimeout=5 "$builder" "cat '$logfile' 2>/dev/null" || true
    rc="$(ssh -o ConnectTimeout=5 "$builder" "cat '$rcfile' 2>/dev/null" || echo 1)"
    break
  fi
  # Hold the -L port-forward for the caller's health checks while we
  # stream the serial log. `tail -F` never reaches EOF on its own, so
  # the remote side also watches for the rc file and kills tail the
  # moment the guest exits -- otherwise the stream would block forever
  # after the guest is gone and we'd never re-check the rc file. On a
  # network drop this remote watcher gets SIGHUP and dies too, so the
  # loop reconnects and replays.
  ssh -L "${ssh_port}:localhost:${ssh_port}" \
    -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o ConnectTimeout=10 \
    -o ExitOnForwardFailure=yes \
    "$builder" "
            tail -n +1 -F '$logfile' 2>/dev/null &
            _tp=\$!
            while [ ! -f '$rcfile' ]; do sleep 0.5; done
            kill \$_tp 2>/dev/null
        " || true
  sleep 1
done

exit "${rc:-1}"
