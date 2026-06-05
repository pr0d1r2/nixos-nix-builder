#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n scripts/test-boot/interpret-qemu-rc.sh
    [ "$status" -eq 0 ]
}

@test "exits 2 with no arguments" {
    run bash scripts/test-boot/interpret-qemu-rc.sh
    [ "$status" -eq 2 ]
}

@test "exits 0 for clean shutdown" {
    run bash scripts/test-boot/interpret-qemu-rc.sh 0
    [ "$status" -eq 0 ]
    [[ "$output" =~ "cleanly" ]]
}

@test "exits 1 for general failure" {
    run bash scripts/test-boot/interpret-qemu-rc.sh 1
    [ "$status" -eq 1 ]
}

@test "exits 1 for SIGKILL" {
    run bash scripts/test-boot/interpret-qemu-rc.sh 137
    [ "$status" -eq 1 ]
    [[ "$output" =~ "SIGKILL" ]]
}

@test "exits 1 for SIGTERM" {
    run bash scripts/test-boot/interpret-qemu-rc.sh 143
    [ "$status" -eq 1 ]
    [[ "$output" =~ "SIGTERM" ]]
}

@test "exits 1 for unknown code" {
    run bash scripts/test-boot/interpret-qemu-rc.sh 42
    [ "$status" -eq 1 ]
    [[ "$output" =~ "42" ]]
}
