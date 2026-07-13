#!/usr/bin/env bash
# Write a self-contained QEMU launch script (run-qemu.sh) that can
# be executed directly without nix-shell (uses full nix store path).
#
# Usage: qemu-cmd.sh <iso-path> <work-dir> [boot-dir]
#   iso-path    path to the ISO on the machine that will run QEMU
#   work-dir    directory for run-qemu.sh + test drives
#   boot-dir    if set, use direct kernel boot from extracted files
#
# Writes <work-dir>/run-qemu.sh and prints its path.

set -Eeuo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "Usage: qemu-cmd.sh <iso-path> <work-dir> [boot-dir]" >&2
  exit 2
fi

iso="$1"
work_dir="$2"
boot_dir="${3:-}"

MEMORY="${QEMU_MEMORY:-16G}"
CPUS="${QEMU_SMP:-8}"
QEMU_BIN="$(command -v qemu-system-x86_64)"
RUN_SCRIPT="$work_dir/run-qemu.sh"

BOOT_ARGS=""
APPEND_LINE=""
if [ -n "$boot_dir" ] && [ -f "$boot_dir/bzImage" ]; then
  BOOT_ARGS="-kernel $boot_dir/bzImage -initrd $boot_dir/initrd"
  CMDLINE=""
  if [ -f "$boot_dir/cmdline" ]; then
    CMDLINE="$(cat "$boot_dir/cmdline")"
  elif [ -f "$boot_dir/init-path" ]; then
    CMDLINE="init=$(cat "$boot_dir/init-path") loglevel=4"
  fi
  # C24: inject the serial console at QEMU runtime so the ISO stays
  # clean (bare metal has no serial-getty). Idempotent -- the extracted
  # grub cmdline no longer bakes console=, but an older ISO might.
  case "$CMDLINE" in
  *console=ttyS0*) ;;
  *) CMDLINE="$CMDLINE console=tty0 console=ttyS0,115200n8" ;;
  esac
  CMDLINE="$CMDLINE nixbuilder.hostname=nix-builder-qemu"
  APPEND_LINE="-append \"$CMDLINE\""
else
  BOOT_ARGS="-boot d"
fi

DRIVE_ARGS=""
if [ -f "$work_dir/nvme1.img" ]; then
  DRIVE_ARGS="$DRIVE_ARGS -drive file=$work_dir/nvme1.img,if=none,id=nvme-d1,format=raw"
  DRIVE_ARGS="$DRIVE_ARGS -device nvme,serial=NVMETEST1,drive=nvme-d1"
fi
if [ -f "$work_dir/nvme2.img" ]; then
  DRIVE_ARGS="$DRIVE_ARGS -drive file=$work_dir/nvme2.img,if=none,id=nvme-d2,format=raw"
  DRIVE_ARGS="$DRIVE_ARGS -device nvme,serial=NVMETEST2,drive=nvme-d2"
fi
if [ -f "$work_dir/sata1.img" ]; then
  DRIVE_ARGS="$DRIVE_ARGS -device ahci,id=ahci0"
  DRIVE_ARGS="$DRIVE_ARGS -drive file=$work_dir/sata1.img,if=none,id=sata-d1,format=raw"
  DRIVE_ARGS="$DRIVE_ARGS -device ide-hd,drive=sata-d1,bus=ahci0.0"
fi

cat >"$RUN_SCRIPT" <<QEOF
#!/usr/bin/env bash
$QEMU_BIN \\
    -enable-kvm -cpu host \\
    -m $MEMORY -smp $CPUS \\
    -display none -serial stdio -monitor none -no-reboot \\
    -cdrom $iso \\
    $BOOT_ARGS \\
    $APPEND_LINE \\
    $DRIVE_ARGS \\
    -virtfs local,path=/nix/store,mount_tag=nix-host-store,security_model=none,readonly=on \\
    -fw_cfg name=opt/nixos-nix-builder/fw_test_gw,string=10.0.2.2 \\
    -fw_cfg name=opt/nixos-nix-builder/nix_cache_url,string=http://10.0.2.2:5000 \\
    -fw_cfg name=opt/nixos-nix-builder/hostname,string=nix-builder-qemu \\
    -net nic,model=virtio-net-pci -net user,hostfwd=tcp:127.0.0.1:2222-:22
QEOF

echo "$RUN_SCRIPT"
