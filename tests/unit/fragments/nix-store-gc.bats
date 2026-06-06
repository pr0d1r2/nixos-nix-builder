#!/usr/bin/env bats

@test "fragment file exists" {
    [ -f fragments/nix-store-gc.sh ]
}

@test "checks disk usage percentage" {
    grep -q 'df.*pcent.*nix/store' fragments/nix-store-gc.sh
}

@test "default threshold is 80%" {
    grep -q 'NIX_GC_THRESHOLD:-80' fragments/nix-store-gc.sh
}

@test "threshold is configurable via env" {
    grep -q 'NIX_GC_THRESHOLD' fragments/nix-store-gc.sh
}

@test "skips GC when below threshold" {
    grep -q 'below threshold' fragments/nix-store-gc.sh
}

@test "uses nix-collect-garbage with delete-older-than 1d" {
    grep -q 'nix-collect-garbage --delete-older-than 1d' fragments/nix-store-gc.sh
}

@test "reports usage after GC" {
    grep -q 'usage_after' fragments/nix-store-gc.sh
}

@test "lint clean" {
    run shellcheck fragments/nix-store-gc.sh
    [ "$status" -eq 0 ]
}
