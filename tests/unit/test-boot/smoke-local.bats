#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n scripts/test-boot/smoke-local.sh
    [ "$status" -eq 0 ]
}

@test "exits 1 when no ISO found" {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/scripts/test-boot" "$TEST_DIR/iso"
    cp scripts/test-boot/smoke-local.sh "$TEST_DIR/scripts/test-boot/"
    run bash "$TEST_DIR/scripts/test-boot/smoke-local.sh"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "no ISO found" ]]
    rm -rf "$TEST_DIR"
}
