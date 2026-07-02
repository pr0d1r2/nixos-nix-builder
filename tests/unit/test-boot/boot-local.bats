#!/usr/bin/env bats

@test "exits 2 with wrong argument count" {
    run bash scripts/test-boot/boot-local.sh
    [ "$status" -eq 2 ]
}

@test "exits 2 with too few arguments" {
    run bash scripts/test-boot/boot-local.sh /tmp /tmp/test.iso # nolocalpath
    [ "$status" -eq 2 ]
}
