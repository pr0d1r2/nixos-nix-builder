#!/usr/bin/env bash
set -euo pipefail

CMDLINE=$(cat /proc/cmdline)
FW_CFG="/sys/firmware/qemu_fw_cfg/by_name/opt/nixos-nix-builder/hostname/raw"

OVERRIDE=""
for param in $CMDLINE; do
  case "$param" in
    nixbuilder.hostname=?*)
      OVERRIDE="${param#nixbuilder.hostname=}"
      ;;
  esac
done

if [ -z "$OVERRIDE" ]; then
  modprobe qemu_fw_cfg 2>/dev/null || true
  if [ -f "$FW_CFG" ]; then
    OVERRIDE=$(cat "$FW_CFG")
  fi
fi

if [ -z "$OVERRIDE" ]; then
  echo "qemu-hostname: no hostname override, skipping"
  exit 0
fi

echo "qemu-hostname: setting hostname to $OVERRIDE"
hostname "$OVERRIDE"
