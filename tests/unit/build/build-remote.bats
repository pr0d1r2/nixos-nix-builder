#!/usr/bin/env bats

@test "exits 2 with wrong argument count" {
    run bash scripts/build/build-remote.sh
    [ "$status" -eq 2 ]
}

@test "script is valid bash" {
    run bash -n scripts/build/build-remote.sh
    [ "$status" -eq 0 ]
}
