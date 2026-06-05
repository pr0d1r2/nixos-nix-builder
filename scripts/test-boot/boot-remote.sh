#!/usr/bin/env bash
# Remote boot on nix-builder.local. Uploads ISO, creates drives,
# boots QEMU over SSH with serial console forwarded back.
#
# Usage: boot-remote.sh <repo-root> <iso-path> <ssh-port> <builder-host>

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "boot: FAILED at scripts/test-boot/boot-remote.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

if [ $# -ne 4 ]; then
    echo "Usage: boot-remote.sh <repo-root> <iso-path> <ssh-port> <builder-host>" >&2
    exit 2
fi

REPO_ROOT="$1"
ISO_PATH="$2"
SSH_PORT="$3"
BUILDER="$4"

ISO_NAME=$(basename "$ISO_PATH")

echo "boot: uploading ISO to $BUILDER"
rsync -z --progress "$ISO_PATH" "root@${BUILDER}:/tmp/${ISO_NAME}"

echo "boot: syncing scripts to $BUILDER"
rsync -a "$REPO_ROOT/scripts/" "root@${BUILDER}:/tmp/nix-builder-scripts/"

echo "boot: creating test drives on $BUILDER"
ssh "root@${BUILDER}" "bash /tmp/nix-builder-scripts/test-boot/create-drives.sh /tmp/nix-builder-drives" >/dev/null

echo "boot: booting $ISO_NAME on $BUILDER via QEMU"
echo "boot: SSH to guest: ssh root@${BUILDER} -p $SSH_PORT (from builder)"
echo "boot: serial console below (Ctrl-C to exit)"
echo
ssh -t "root@${BUILDER}" \
    "nix-shell -p qemu nix-serve --run \"trap 'kill 0; wait' EXIT HUP INT TERM; nix-serve -p 5000 & \$(bash /tmp/nix-builder-scripts/test-boot/qemu-cmd.sh /tmp/${ISO_NAME} ${SSH_PORT} /tmp/nix-builder-drives) & wait\""
