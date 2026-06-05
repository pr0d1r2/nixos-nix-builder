#!/usr/bin/env bash
# Local-Linux interactive boot. Launches QEMU with SSH port-forwarding
# and nix-serve on :5000 for binary cache.
#
# Usage: boot-local.sh <repo-root> <iso-path> <ssh-port>

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "boot: FAILED at scripts/test-boot/boot-local.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

if [ $# -ne 3 ]; then
    echo "Usage: boot-local.sh <repo-root> <iso-path> <ssh-port>" >&2
    exit 2
fi

REPO_ROOT="$1"
ISO_PATH="$2"
SSH_PORT="$3"

drives_dir=$(mktemp -d)
trap 'rm -rf "$drives_dir"' EXIT
echo "boot: creating virtual test drives in $drives_dir"
bash "$REPO_ROOT/scripts/test-boot/create-drives.sh" "$drives_dir" >/dev/null

bootinfo_path="${ISO_PATH%.iso}.bootinfo"
if [ -f "$bootinfo_path" ]; then
    # shellcheck source=/dev/null
    . "$bootinfo_path"
    export QEMU_KERNEL QEMU_INITRD QEMU_INIT QEMU_KERNEL_PARAMS
fi

echo "boot: booting ISO in QEMU locally"
echo "boot: SSH available at: ssh root@localhost -p $SSH_PORT"
echo "boot: serial console below (Ctrl-C to exit)"
echo
rc=0
nix-shell -p qemu nix-serve --run "trap 'kill 0; wait' EXIT HUP INT TERM; nix-serve -p 5000 & $(bash "$REPO_ROOT/scripts/test-boot/qemu-cmd.sh" "$ISO_PATH" "$SSH_PORT" "$drives_dir") & wait" || rc=$?
exit "$rc"
