#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/scripts/test-boot"
    cp scripts/test-boot/smoke-mark.sh "$TEST_DIR/scripts/test-boot/"
    cd "$TEST_DIR" || return
    git init -q
    git commit --allow-empty -m "init" -q
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "creates marker file for current SHA" {
    bash "$TEST_DIR/scripts/test-boot/smoke-mark.sh"
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    [ -f "$TEST_DIR/.smoke-passed-$SHORT_SHA" ]
}

@test "marker contains timestamp" {
    bash "$TEST_DIR/scripts/test-boot/smoke-mark.sh"
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    content="$(cat "$TEST_DIR/.smoke-passed-$SHORT_SHA")"
    [[ "$content" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2} ]]
}
