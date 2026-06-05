#!/usr/bin/env bats

@test "script exists and is valid bash" {
    run bash -n scripts/build/build.sh
    [ "$status" -eq 0 ]
}

@test "macOS early exit when no builder reachable" {
    grep -q 'no builder reachable' scripts/build/build.sh
}
