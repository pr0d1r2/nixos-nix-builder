#!/usr/bin/env bats

@test "script exists and is valid bash" {
    run bash -n scripts/build/build.sh
    [ "$status" -eq 0 ]
}

@test "macOS early exit when no builder reachable" {
    grep -q 'no builder reachable' scripts/build/build.sh
}

@test "Darwin keeps the ISO on the builder (no download)" {
    grep -q 'ISO kept on builder' scripts/build/build.sh
}
