#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/scripts/burn"
    cp scripts/burn/burn-check.sh "$TEST_DIR/scripts/burn/"
    cd "$TEST_DIR" || return
    git init -q
    git -c user.name=test -c user.email=test@test commit --allow-empty -m "init" -q
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "exits 1 when no marker exists" {
    run bash "$TEST_DIR/scripts/burn/burn-check.sh"
    [ "$status" -eq 1 ]
}

@test "exits 0 when marker exists for current SHA" {
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    date -Iseconds >"$TEST_DIR/.burn-done-$SHORT_SHA"
    run bash "$TEST_DIR/scripts/burn/burn-check.sh"
    [ "$status" -eq 0 ]
}

@test "exits 1 when marker exists for different SHA" {
    echo "old" >"$TEST_DIR/.burn-done-aaaaaaa"
    run bash "$TEST_DIR/scripts/burn/burn-check.sh"
    [ "$status" -eq 1 ]
}

@test "prints timestamp when marker exists" {
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    echo "2026-05-26T14:00:00+00:00" >"$TEST_DIR/.burn-done-$SHORT_SHA"
    run bash "$TEST_DIR/scripts/burn/burn-check.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "2026-05-26" ]]
}
