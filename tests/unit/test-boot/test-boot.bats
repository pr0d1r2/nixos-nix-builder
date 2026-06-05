#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n scripts/test-boot/test-boot.sh
    [ "$status" -eq 0 ]
}

@test "invokes expect smoke.exp" {
    grep -q 'smoke.exp' scripts/test-boot/test-boot.sh
}
