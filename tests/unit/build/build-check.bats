#!/usr/bin/env bats

@test "exits 1 when no ISO exists" {
    tmp="$(mktemp -d)"
    export HOME="$tmp"
    mkdir -p "$tmp/iso"
    git -C "$tmp" init -q
    cp scripts/build/build-check.sh "$tmp/scripts/build/build-check.sh" 2>/dev/null || {
        mkdir -p "$tmp/scripts/build" "$tmp/scripts/lib"
        cp scripts/build/build-check.sh "$tmp/scripts/build/"
        cp scripts/build/iso_store_dir.sh "$tmp/scripts/build/"
        cp scripts/lib/find-builder.sh "$tmp/scripts/lib/"
    }
    git -C "$tmp" add -A
    git -C "$tmp" -c user.name=test -c user.email=test@test commit -q -m "init"
    run bash "$tmp/scripts/build/build-check.sh"
    [ "$status" -eq 1 ]
    rm -rf "$tmp"
}
