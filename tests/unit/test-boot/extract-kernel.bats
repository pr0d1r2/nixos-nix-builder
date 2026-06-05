#!/usr/bin/env bats

@test "exits with error when no arguments" {
    run bash scripts/test-boot/extract-kernel.sh
    [ "$status" -ne 0 ]
}

@test "no grep -P in script" {
    run ! grep -q 'grep.*-[a-zA-Z]*P' scripts/test-boot/extract-kernel.sh
}
