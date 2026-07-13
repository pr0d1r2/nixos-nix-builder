#!/usr/bin/env bash
set -euo pipefail

FW_CFG="/sys/firmware/qemu_fw_cfg/by_name/opt/nixos-nix-builder/nix_cache_url/raw"

modprobe qemu_fw_cfg 2>/dev/null || true

if [ ! -f "$FW_CFG" ]; then
  echo "qemu-nix-cache: no fw_cfg entry, skipping (real hardware)"
  exit 0
fi

CACHE_URL=$(cat "$FW_CFG")

if ! [[ "$CACHE_URL" =~ ^https?:// ]]; then
  echo "qemu-nix-cache: invalid cache URL '$CACHE_URL', skipping" >&2
  exit 1
fi

echo "qemu-nix-cache: adding substituter $CACHE_URL"

mkdir -p /etc/nix
cat >>/etc/nix/nix.conf <<EOF
extra-substituters = $CACHE_URL
extra-trusted-substituters = $CACHE_URL
require-sigs = false
EOF

systemctl restart nix-daemon 2>/dev/null || true
