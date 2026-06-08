#!/usr/bin/env bats

@test "exits 2 with wrong argument count" {
    run bash scripts/test-boot/boot-remote.sh
    [ "$status" -eq 2 ]
}

@test "exits 2 with too few arguments" {
    run bash scripts/test-boot/boot-remote.sh /tmp 2222
    [ "$status" -eq 2 ]
}

@test "reads ISO from the builder store" {
    grep -q 'iso_store_dir.sh' scripts/test-boot/boot-remote.sh
}

@test "does not upload an ISO to the builder" {
    run ! grep -q 'rsync.*\.iso' scripts/test-boot/boot-remote.sh
}
