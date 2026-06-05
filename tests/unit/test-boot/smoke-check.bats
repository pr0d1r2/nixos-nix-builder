#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/scripts/test-boot"
    cp scripts/test-boot/smoke-check.sh "$TEST_DIR/scripts/test-boot/"
    cd "$TEST_DIR" || return
    git init -q
    git commit --allow-empty -m "init" -q
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "exits 1 when no marker exists" {
    run bash "$TEST_DIR/scripts/test-boot/smoke-check.sh"
    [ "$status" -eq 1 ]
}

@test "exits 0 when marker exists for current SHA" {
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    date -Iseconds >"$TEST_DIR/.smoke-passed-$SHORT_SHA"
    run bash "$TEST_DIR/scripts/test-boot/smoke-check.sh"
    [ "$status" -eq 0 ]
}

@test "exits 1 when marker exists for different SHA" {
    echo "old" >"$TEST_DIR/.smoke-passed-aaaaaaa"
    run bash "$TEST_DIR/scripts/test-boot/smoke-check.sh"
    [ "$status" -eq 1 ]
}
