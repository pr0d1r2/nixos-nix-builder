#!/usr/bin/env bats

@test "exits with error when no arguments" {
    run bash scripts/test-boot/create-drives.sh
    [ "$status" -ne 0 ]
}

@test "has trap-based losetup cleanup" {
    grep -q 'trap.*losetup' scripts/test-boot/create-drives.sh
}
