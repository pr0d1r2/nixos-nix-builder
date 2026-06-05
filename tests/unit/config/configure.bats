#!/usr/bin/env bats

@test "script exists and is valid bash" {
    run bash -n scripts/config/configure.sh
    [ "$status" -eq 0 ]
}
