#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "script is valid bash" {
    run bash -n scripts/burn/list-usb.sh
    [ "$status" -eq 0 ]
}

@test "reads from fake backend when NIX_BUILDER_BURN_FAKE_BACKEND set" {
    echo "/dev/sda|128G|Kingston" >"$TEST_DIR/fake-usb"
    run env NIX_BUILDER_BURN_FAKE_BACKEND="$TEST_DIR/fake-usb" \
        bash scripts/burn/list-usb.sh
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/dev/sda|128G|Kingston" ]]
}

@test "exits 1 when no devices found" {
    echo "" >"$TEST_DIR/fake-usb"
    run env NIX_BUILDER_BURN_FAKE_BACKEND="$TEST_DIR/fake-usb" \
        bash scripts/burn/list-usb.sh
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No USB block devices detected" ]]
}

@test "dispatches to linux on Linux" {
    grep -q 'list-usb-linux.sh' scripts/burn/list-usb.sh
}

@test "dispatches to macos on Darwin" {
    grep -q 'list-usb-macos.sh' scripts/burn/list-usb.sh
}
