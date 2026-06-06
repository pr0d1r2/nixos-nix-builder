#!/usr/bin/env bats

@test "fragment file exists" {
    [ -f fragments/qemu-9p-store-mount.sh ]
}

@test "mounts with virtio transport and 9p2000.L" {
    grep -q 'trans=virtio,version=9p2000.L' fragments/qemu-9p-store-mount.sh
}

@test "mounts read-only" {
    grep -q ',ro,' fragments/qemu-9p-store-mount.sh
}

@test "uses 1MB msize for performance" {
    grep -q 'msize=1048576' fragments/qemu-9p-store-mount.sh
}

@test "uses cache=loose for read-only performance" {
    grep -q 'cache=loose' fragments/qemu-9p-store-mount.sh
}

@test "loads 9p kernel modules" {
    grep -q 'modprobe 9p 9pnet_virtio' fragments/qemu-9p-store-mount.sh
}

@test "mount tag matches qemu-cmd.sh virtfs tag" {
    qemu_tag=$(grep -o 'mount_tag=[^,]*' scripts/test-boot/qemu-cmd.sh | head -1 | cut -d= -f2)
    fragment_tag=$(grep '^mount -t 9p' fragments/qemu-9p-store-mount.sh | awk '{print $4}')
    [ "$qemu_tag" = "$fragment_tag" ]
}

@test "lint clean" {
    run shellcheck fragments/qemu-9p-store-mount.sh
    [ "$status" -eq 0 ]
}
