#!/usr/bin/env bats

@test "module file exists" {
    [ -f modules/nix-store-gc.nix ]
}

@test "service is oneshot type" {
    grep -q 'Type.*=.*"oneshot"' modules/nix-store-gc.nix
}

@test "service runs after nix-store-overlay" {
    grep -q 'after.*nix-store-overlay.service' modules/nix-store-gc.nix
}

@test "service reads GC fragment" {
    grep -q 'builtins.readFile.*fragments/nix-store-gc.sh' modules/nix-store-gc.nix
}

@test "timer triggers on boot" {
    grep -q 'OnBootSec' modules/nix-store-gc.nix
}

@test "timer repeats hourly" {
    grep -q 'OnUnitActiveSec.*1h' modules/nix-store-gc.nix
}

@test "timer has randomized delay" {
    grep -q 'RandomizedDelaySec' modules/nix-store-gc.nix
}

@test "timer wanted by timers.target" {
    grep -q 'timers.target' modules/nix-store-gc.nix
}

@test "module imported in default.nix" {
    grep -q 'nix-store-gc.nix' modules/default.nix
}
