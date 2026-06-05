#!/usr/bin/env bats

@test "does nothing when all settings present" {
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/config/user" "$tmp/scripts/config" "$tmp/secrets"
    for s in timezone locale keymap fstype; do
        echo "test" >"$tmp/config/user/$s"
    done
    touch "$tmp/secrets/authorized_keys"
    touch "$tmp/secrets/ssh_host_ed25519_key"
    touch "$tmp/secrets/signing-key.sec"
    cp scripts/config/check.sh "$tmp/scripts/config/"
    cp scripts/config/ensure.sh "$tmp/scripts/config/"
    cp scripts/config/configure.sh "$tmp/scripts/config/"
    cp scripts/config/setup-secrets.sh "$tmp/scripts/config/"
    run bash "$tmp/scripts/config/ensure.sh"
    [ "$status" -eq 0 ]
    rm -rf "$tmp"
}

@test "calls setup-secrets" {
    run grep 'setup-secrets' scripts/config/ensure.sh
    [ "$status" -eq 0 ]
}
