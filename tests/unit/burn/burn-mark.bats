#!/usr/bin/env bats

setup() {
    TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/scripts/burn"
    cp scripts/burn/burn-mark.sh "$TEST_DIR/scripts/burn/"
    cd "$TEST_DIR" || return
    git init -q
    git -c user.name=test -c user.email=test@test commit --allow-empty -m "init" -q
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "creates marker file for current SHA" {
    bash "$TEST_DIR/scripts/burn/burn-mark.sh"
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    [ -f "$TEST_DIR/.burn-done-$SHORT_SHA" ]
}

@test "marker contains timestamp" {
    bash "$TEST_DIR/scripts/burn/burn-mark.sh"
    SHORT_SHA="$(git rev-parse --short=7 HEAD)"
    content="$(cat "$TEST_DIR/.burn-done-$SHORT_SHA")"
    [[ "$content" =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2} ]]
}
