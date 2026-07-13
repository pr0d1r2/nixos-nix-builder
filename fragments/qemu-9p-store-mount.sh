#!/usr/bin/env bash
set -uo pipefail

MOUNT_POINT="/mnt/nix-host-store"

modprobe 9p 9pnet_virtio 2>/dev/null || true

mkdir -p "$MOUNT_POINT"

mount -t 9p nix-host-store "$MOUNT_POINT" \
  -o trans=virtio,version=9p2000.L,ro,msize=1048576,cache=loose

echo "qemu-9p-store: mounted host nix store at $MOUNT_POINT" >&2
