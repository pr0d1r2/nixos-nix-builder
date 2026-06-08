#!/usr/bin/env bash
# Remote boot on nix-builder.local. Boots the builder-resident ISO in
# QEMU over SSH with serial console forwarded back. Remote-first: the ISO
# is read from the builder store, never uploaded from this host.
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

echo "boot: syncing scripts to $BUILDER"
rsync -a "$REPO_ROOT/scripts/" "${builder_ssh}:/tmp/nix-builder-scripts/"

echo "boot: creating test drives on $BUILDER"
ssh "$builder_ssh" "bash /tmp/nix-builder-scripts/test-boot/create-drives.sh /tmp/nix-builder-drives" >/dev/null

echo "boot: booting $ISO_NAME on $BUILDER via QEMU"
echo "boot: SSH to guest: ssh root@${BUILDER} -p $SSH_PORT (from builder)"
echo "boot: serial console below (Ctrl-C to exit)"
echo
# shellcheck disable=SC2029
ssh -t "$builder_ssh" \
    "nix-shell -p qemu nix-serve --run \"trap 'kill 0; wait' EXIT HUP INT TERM; nix-serve -p 5000 & \$(bash /tmp/nix-builder-scripts/test-boot/qemu-cmd.sh '$remote_iso' ${SSH_PORT} /tmp/nix-builder-drives) & wait\""
