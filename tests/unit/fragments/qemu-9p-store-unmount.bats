#!/usr/bin/env bats

@test "fragment file exists" {
  [ -f fragments/qemu-9p-store-unmount.sh ]
}

@test "handles missing mount gracefully" {
  grep -q 'umount /mnt/nix-host-store 2>/dev/null || true' fragments/qemu-9p-store-unmount.sh
}

@test "lint clean" {
  run shellcheck fragments/qemu-9p-store-unmount.sh
  [ "$status" -eq 0 ]
}
