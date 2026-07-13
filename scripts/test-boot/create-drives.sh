#!/usr/bin/env bash
# Create partitioned+ext4-formatted disk images for smoke-testing
# the NVMe > SATA storage tier selection.
#
# Three drives:
#   nvme1.img   64 MB, one ext4 partition
#   nvme2.img  512 MB, one ext4 partition  -- should win (largest on fastest tier)
#   sata1.img  384 MB, one ext4 partition  -- bigger but slower tier
#
# Usage: create-drives.sh <output-dir>
# Requires root (losetup + mkfs.ext4). Linux only.

set -euo pipefail

dir="${1:?Usage: create-drives.sh <output-dir>}"
mkdir -p "$dir"

rm -f "$dir/nvme1.img" "$dir/sata1.img"

for spec in nvme1:64 nvme2:512 sata1:384; do
  name="${spec%%:*}"
  size_mb="${spec##*:}"
  img="$dir/${name}.img"

  if [ -f "$img" ] && [ "$name" = "nvme2" ]; then
    echo "create-drives: reusing $name.img ($(du -h "$img" | cut -f1))" >&2
    continue
  fi

  truncate -s "${size_mb}M" "$img"
  printf 'type=83\n' | sfdisk -q "$img" >/dev/null 2>&1

  loop=$(losetup --find --show --partscan "$img")
  trap 'losetup -d "$loop" 2>/dev/null || true' EXIT ERR
  part="${loop}p1"
  i=0
  while [ ! -b "$part" ] && [ "$i" -lt 50 ]; do
    sleep 0.1
    i=$((i + 1))
  done
  if [ ! -b "$part" ]; then
    echo "create-drives: partition device $part did not appear" >&2
    exit 1
  fi
  mkfs.ext4 -q -F "$part" >/dev/null 2>&1
  losetup -d "$loop"
  trap - EXIT ERR
done

echo "$dir"
