#!/usr/bin/env bats

@test "exports NIX_BUILDER_BURN_BUILD=1" {
    run grep 'NIX_BUILDER_BURN_BUILD=1' scripts/build/build-for-burn.sh
    [ "$status" -eq 0 ]
}

@test "calls build-check.sh" {
    run grep 'build-check.sh' scripts/build/build-for-burn.sh
    [ "$status" -eq 0 ]
}

@test "falls back to build.sh" {
    run grep 'build.sh' scripts/build/build-for-burn.sh
    [ "$status" -eq 0 ]
}
