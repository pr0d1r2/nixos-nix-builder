#!/usr/bin/env bash
# Remote boot on nix-builder.local. Boots the builder-resident ISO in a
# DETACHED tmux session on the builder (via qemu-remote-tmux.sh), so a
# transient mac<->builder ssh drop no longer SIGHUPs QEMU mid-boot; the
# serial streams back with reconnect and the -L forward is held for SSH.
# Remote-first: the ISO is read from the builder store, never uploaded.
#
# Usage: boot-remote.sh <repo-root> <ssh-port> <builder-host>

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "boot: FAILED at scripts/test-boot/boot-remote.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

if [ $# -ne 3 ]; then
    echo "Usage: boot-remote.sh <repo-root> <ssh-port> <builder-host>" >&2
    exit 2
fi

REPO_ROOT="$1"
SSH_PORT="$2"
BUILDER="$3"

builder_ssh="root@${BUILDER}"

# Resolve the newest ISO already staged in the builder store. Nothing is
# uploaded -- `just build` leaves the ISO on the builder.
store_dir="$(ssh "$builder_ssh" sh <"$REPO_ROOT/scripts/build/iso_store_dir.sh")"
# shellcheck disable=SC2029
remote_iso="$(ssh "$builder_ssh" "ls -t '$store_dir/'*.iso 2>/dev/null | head -n1" || true)"
if [ -z "$remote_iso" ]; then
    echo "boot: no ISO in $BUILDER store ($store_dir) -- run 'just build' first" >&2
    exit 1
fi
ISO_NAME="$(basename "$remote_iso")"

work_parent="$(ssh "$builder_ssh" 'if mountpoint -q /mnt/storage 2>/dev/null; then echo /mnt/storage/tmp; else echo /tmp; fi')"
WORK_DIR="$work_parent/nix-builder-boot"
SESSION="nix-builder-boot"

# shellcheck disable=SC2029
ssh "$builder_ssh" "mkdir -p '$WORK_DIR/scripts'"
echo "boot: syncing scripts to $BUILDER"
rsync -rlptDz --delete "$REPO_ROOT/scripts/test-boot/" "${builder_ssh}:$WORK_DIR/scripts/"

echo "boot: creating test drives + QEMU launch script on $BUILDER"
# shellcheck disable=SC2029
ssh "$builder_ssh" "nix-shell -p qemu --run \
    \"bash '$WORK_DIR/scripts/create-drives.sh' '$WORK_DIR' && \
    bash '$WORK_DIR/scripts/qemu-cmd.sh' '$remote_iso' '$WORK_DIR'\"" >/dev/null

# shellcheck disable=SC2029
ssh "$builder_ssh" "pkill -f 'qemu-system-x86_64.*hostfwd=tcp.*:2222' 2>/dev/null; pkill -f '$SESSION' 2>/dev/null; sleep 0.5" || true

echo "boot: booting $ISO_NAME on $BUILDER via QEMU (detached tmux)"
echo "boot: SSH to guest: ssh root@${BUILDER} -p $SSH_PORT (from builder)"
echo "boot: serial console below (Ctrl-C to exit)"
echo
# Detach the boot guest into a builder tmux session. nix-serve rides on
# PATH (extra pkg) for the guest's binary cache; boot-run.sh starts it.
exec bash "$REPO_ROOT/scripts/test-boot/qemu-remote-tmux.sh" \
    "$builder_ssh" "$SESSION" "$SSH_PORT" "$WORK_DIR/scripts/boot-run.sh" "nix-serve"
