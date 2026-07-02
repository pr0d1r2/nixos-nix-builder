#!/usr/bin/env bash
# Boot the nixos-nix-builder ISO in QEMU locally on Linux x86_64 with
# KVM and stream serial output to stdout. Designed to be spawned by
# expect (smoke.exp).
#
# Usage: bash smoke-local.sh [iso-path]

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "smoke-local: FAILED at scripts/test-boot/smoke-local.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHORT_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")"
if [ -d /mnt/storage ]; then
    WORK_DIR="/mnt/storage/tmp/nix-builder-qemu-test-${SHORT_SHA}" # nolocalpath
else
    WORK_DIR="/tmp/nix-builder-qemu-test-${SHORT_SHA}" # nolocalpath
fi

ISO="${1:-}"
if [ -z "$ISO" ]; then
    # shellcheck disable=SC2012
    ISO="$(ls -t "$REPO_ROOT/iso/"*.iso 2>/dev/null | head -n1 || true)"
    if [ -z "$ISO" ]; then
        echo "smoke-local: no ISO found in $REPO_ROOT/iso/. Run 'just build' first." >&2
        exit 1
    fi
fi

echo "smoke-local: ISO = $(basename "$ISO")" >&2
echo "smoke-local: work dir = $WORK_DIR" >&2

mkdir -p "$WORK_DIR"

echo "smoke-local: creating virtual drives..." >&2
bash "$REPO_ROOT/scripts/test-boot/create-drives.sh" "$WORK_DIR" >&2

QEMU_CMD="$(bash "$REPO_ROOT/scripts/test-boot/qemu-cmd.sh" "$ISO" 2222 "$WORK_DIR")"

{
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    echo "$QEMU_CMD"
} >"$WORK_DIR/run-qemu.sh"

echo >&2
echo "smoke-local: booting $(basename "$ISO") in QEMU locally (Ctrl-C to exit)" >&2
echo >&2

exec nix-shell -p qemu --run "bash '$WORK_DIR/run-qemu.sh'"
