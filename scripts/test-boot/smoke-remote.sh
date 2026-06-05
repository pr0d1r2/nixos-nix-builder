#!/usr/bin/env bash
# Boot the nixos-nix-builder ISO in QEMU on nix-builder.local and
# stream serial output back to the caller's stdout. Designed to be
# spawned by expect (smoke.exp) on macOS.
#
# Usage: bash smoke-remote.sh [iso-path]

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "smoke-remote: FAILED at scripts/test-boot/smoke-remote.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILDER="$(bash "$REPO_ROOT/scripts/lib/find-builder.sh")"
SHORT_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD)"
WORK_DIR="/mnt/storage/tmp/nix-builder-qemu-test-${SHORT_SHA}"
STORE_DIR="$(ssh "$BUILDER" sh <"$REPO_ROOT/scripts/build/iso_store_dir.sh")"

ISO="${1:-}"
if [ -z "$ISO" ]; then
    # shellcheck disable=SC2012
    ISO="$(ls -t "$REPO_ROOT/iso/"*"${SHORT_SHA}"*.iso 2>/dev/null | head -n1 || true)"
fi

# shellcheck disable=SC2029
REMOTE_ISO="$(ssh "$BUILDER" "ls -t '$STORE_DIR/'*'${SHORT_SHA}'*.iso 2>/dev/null | head -n1" || true)"

if [ -n "$REMOTE_ISO" ]; then
    ISO_NAME="$(basename "$REMOTE_ISO")"
    echo "smoke-remote: reusing $BUILDER:$REMOTE_ISO (already staged)" >&2
elif [ -n "$ISO" ] && [ -f "$ISO" ]; then
    ISO_NAME="$(basename "$ISO")"
    REMOTE_ISO="$STORE_DIR/$ISO_NAME"
    echo "smoke-remote: uploading $ISO_NAME to builder..." >&2
    rsync -z --progress "$ISO" "$BUILDER:$REMOTE_ISO" >&2
else
    echo "smoke-remote: no ISO for SHA $SHORT_SHA -- building..."
    NIX_BUILDER_BURN_BUILD=1 bash "$REPO_ROOT/scripts/build/build.sh"
    # shellcheck disable=SC2029
    REMOTE_ISO="$(ssh "$BUILDER" "ls -t '$STORE_DIR/'*'${SHORT_SHA}'*.iso 2>/dev/null | head -n1" || true)"
    if [ -z "$REMOTE_ISO" ]; then
        echo "smoke-remote: build did not produce an ISO on builder." >&2
        exit 1
    fi
    ISO_NAME="$(basename "$REMOTE_ISO")"
    echo "smoke-remote: built $ISO_NAME on builder" >&2
fi

echo "smoke-remote: ISO = $ISO_NAME (on builder)" >&2

echo "smoke-remote: syncing scripts to builder..." >&2
# shellcheck disable=SC2029
ssh "$BUILDER" "mkdir -p '$WORK_DIR/scripts'" >&2
rsync -rlptDz --delete \
    "$REPO_ROOT/scripts/test-boot/" "$BUILDER:$WORK_DIR/scripts/" >&2

QEMU_WRAP=""
if ! ssh "$BUILDER" "command -v qemu-system-x86_64 >/dev/null 2>&1"; then
    echo "smoke-remote: qemu not in system PATH, using nix-shell fallback..." >&2
    QEMU_WRAP="nix-shell -p qemu --run"
fi

# shellcheck disable=SC2029
ssh "$BUILDER" "rm -rf '$WORK_DIR/boot'" || true

echo "smoke-remote: creating drives + extracting kernel + generating QEMU script..." >&2
if [ -n "$QEMU_WRAP" ]; then
    # shellcheck disable=SC2029
    ssh "$BUILDER" "nix-shell -p qemu --run \
        \"bash '$WORK_DIR/scripts/create-drives.sh' '$WORK_DIR' && \
        bash '$WORK_DIR/scripts/extract-kernel.sh' '$REMOTE_ISO' '$WORK_DIR/boot' && \
        bash '$WORK_DIR/scripts/qemu-cmd.sh' '$REMOTE_ISO' '$WORK_DIR' '$WORK_DIR/boot'\"" >&2
else
    # shellcheck disable=SC2029
    ssh "$BUILDER" "\
        bash '$WORK_DIR/scripts/create-drives.sh' '$WORK_DIR' && \
        bash '$WORK_DIR/scripts/extract-kernel.sh' '$REMOTE_ISO' '$WORK_DIR/boot' && \
        bash '$WORK_DIR/scripts/qemu-cmd.sh' '$REMOTE_ISO' '$WORK_DIR' '$WORK_DIR/boot'" >&2
fi

# shellcheck disable=SC2029
ssh "$BUILDER" "pkill -f 'qemu-system-x86_64.*hostfwd=tcp.*:2222' 2>/dev/null; sleep 0.5" || true

echo >&2
echo "smoke-remote: booting $ISO_NAME in QEMU on $BUILDER (Ctrl-C to exit)" >&2
echo >&2

exec ssh -t "$BUILDER" "bash '$WORK_DIR/run-qemu.sh'"
