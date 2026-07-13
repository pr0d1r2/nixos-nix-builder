#!/usr/bin/env bash
# Extract kernel + initrd from an ISO for direct kernel boot.
#
# Usage: extract-kernel.sh <iso-path> <output-dir>
# Writes: bzImage, initrd, init-path to <output-dir>/

set -euo pipefail

iso="${1:?Usage: extract-kernel.sh <iso-path> <output-dir>}"
out="${2:?Usage: extract-kernel.sh <iso-path> <output-dir>}"

if [ -f "$out/bzImage" ] && [ -f "$out/initrd" ] && [ -f "$out/cmdline" ]; then
  echo "extract-kernel: already extracted, skipping" >&2
  exit 0
fi

mkdir -p "$out"
mnt=$(mktemp -d)
trap 'umount "$mnt" 2>/dev/null; rmdir "$mnt"' EXIT

mount -o ro "$iso" "$mnt"

kernel=$(find "$mnt/boot" -name 'bzImage' -type f | head -n1)
initrd=$(find "$mnt/boot" -name 'initrd' -type f | head -n1)

if [ -z "$kernel" ] || [ -z "$initrd" ]; then
  echo "extract-kernel: bzImage or initrd not found in ISO" >&2
  exit 1
fi

cp "$kernel" "$out/bzImage"
cp "$initrd" "$out/initrd"

grub_cfg=""
for candidate in "$mnt/boot/grub/grub.cfg" "$mnt/EFI/BOOT/grub.cfg"; do
  if [ -f "$candidate" ]; then
    grub_cfg="$candidate"
    break
  fi
done

if [ -z "$grub_cfg" ]; then
  echo "extract-kernel: grub.cfg not found in ISO" >&2
  exit 1
fi

init_path=$(sed -n 's/.*init=\([^ ]*\).*/\1/p' "$grub_cfg" | head -n1)
echo "$init_path" >"$out/init-path"

cmdline=$(sed -n 's|.*linux .*/bzImage \(.*\)|\1|p' "$grub_cfg" | head -n1)
cmdline="${cmdline//\$\{isoboot\}/}"
echo "$cmdline" >"$out/cmdline"

echo "extract-kernel: extracted to $out (init=$init_path)" >&2
