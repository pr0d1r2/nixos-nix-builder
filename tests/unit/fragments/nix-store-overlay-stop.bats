#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n fragments/nix-store-overlay-stop.sh
    [ "$status" -eq 0 ]
}

@test "umounts nix store" {
    grep -q 'umount.*/nix/store' fragments/nix-store-overlay-stop.sh
}

@test "tolerates umount failure" {
    grep -q 'umount.*|| true' fragments/nix-store-overlay-stop.sh
}
