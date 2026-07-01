#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "script is valid bash" {
    run bash -n scripts/burn/list-isos.sh
    [ "$status" -eq 0 ]
}

@test "exits 1 when directory does not exist" {
    run bash scripts/burn/list-isos.sh "$TEST_DIR/nonexistent"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "directory does not exist" ]]
}

@test "exits 1 when no ISOs found" {
    mkdir -p "$TEST_DIR/empty"
    run bash scripts/burn/list-isos.sh "$TEST_DIR/empty"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No ISOs found" ]]
}

@test "lists ISOs newest first" {
    mkdir -p "$TEST_DIR/isos"
    touch "$TEST_DIR/isos/old.iso"
    sleep 0.1
    touch "$TEST_DIR/isos/new.iso"
    run bash scripts/burn/list-isos.sh "$TEST_DIR/isos"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "new.iso" ]
    [ "${lines[1]}" = "old.iso" ]
}

@test "defaults to iso directory" {
    grep -q 'DIR="${1:-iso}"' scripts/burn/list-isos.sh
}
