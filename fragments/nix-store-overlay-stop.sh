# shellcheck shell=bash
set -euo pipefail

umount /nix/store 2>/dev/null || true

echo "nix-store-overlay: disk-backed overlay unmounted" >&2
