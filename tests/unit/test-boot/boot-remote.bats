#!/usr/bin/env bats

@test "exits 2 with wrong argument count" {
    run bash scripts/test-boot/boot-remote.sh
    [ "$status" -eq 2 ]
}

@test "exits 2 with too few arguments" {
    run bash scripts/test-boot/boot-remote.sh /tmp /tmp/test.iso 2222
    [ "$status" -eq 2 ]
}
