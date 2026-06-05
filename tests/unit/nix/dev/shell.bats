#!/usr/bin/env bats

@test "sets LEFTHOOK_TDD_PATHS" {
    run grep 'LEFTHOOK_TDD_PATHS' nix/dev/shell.sh
    [ "$status" -eq 0 ]
}

@test "sets LEFTHOOK_TDD_EXCLUDE" {
    run grep 'LEFTHOOK_TDD_EXCLUDE' nix/dev/shell.sh
    [ "$status" -eq 0 ]
}
