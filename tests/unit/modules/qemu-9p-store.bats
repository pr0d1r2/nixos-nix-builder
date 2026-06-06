#!/usr/bin/env bats

@test "module file exists" {
    [ -f modules/qemu-9p-store.nix ]
}

@test "service runs before nix-store-overlay" {
    grep -q 'before.*nix-store-overlay.service' modules/qemu-9p-store.nix
}

@test "service is oneshot type" {
    grep -q 'Type.*=.*"oneshot"' modules/qemu-9p-store.nix
}

@test "service tolerates mount failure on bare metal" {
    grep -q 'SuccessExitStatus.*32' modules/qemu-9p-store.nix
}

@test "service reads 9p mount fragment" {
    grep -q 'builtins.readFile.*fragments/qemu-9p-store-mount.sh' modules/qemu-9p-store.nix
}

@test "service has preStop for unmount" {
    grep -q 'builtins.readFile.*fragments/qemu-9p-store-unmount.sh' modules/qemu-9p-store.nix
}

@test "unmount fragment exists and is valid" {
    run bash -n fragments/qemu-9p-store-unmount.sh
    [ "$status" -eq 0 ]
}

@test "unmount fragment handles missing mount gracefully" {
    grep -q 'umount /mnt/nix-host-store 2>/dev/null || true' fragments/qemu-9p-store-unmount.sh
}

@test "module imported in default.nix" {
    grep -q 'qemu-9p-store.nix' modules/default.nix
}
