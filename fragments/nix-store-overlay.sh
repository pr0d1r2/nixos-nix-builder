# shellcheck shell=bash
set -euo pipefail

STORAGE="/mnt/storage"
UPPER="$STORAGE/nix-store-upper"
WORK="$STORAGE/nix-store-work"

if [ ! -d "$STORAGE" ]; then
    echo "nix-store-overlay: no storage available, keeping tmpfs overlay" >&2
    exit 0
fi

if [ ! -d /nix/.rw-store/store ] || [ ! -d /nix/.rw-store/work ]; then
    echo "nix-store-overlay: /nix/.rw-store not ready, keeping tmpfs overlay" >&2
    exit 0
fi

mkdir -p "$UPPER" "$WORK"

cp -a /nix/.rw-store/store/. "$UPPER/" 2>/dev/null || true

LOWER="/nix/.ro-store"
if mountpoint -q /mnt/nix-host-store 2>/dev/null; then
    LOWER="/nix/.ro-store:/mnt/nix-host-store"
    echo "nix-store-overlay: including host nix store (9p) as lower layer" >&2
fi

mount -t overlay overlay \
    -o "lowerdir=$LOWER,upperdir=$UPPER,workdir=$WORK" \
    /nix/store

echo "nix-store-overlay: overlay mounted with disk-backed upper from $STORAGE" >&2
