#!/usr/bin/env bats

setup() {
    tmp="$(mktemp -d "$BATS_TEST_TMPDIR/avahi-alias.XXXXXX")"
    cat >"$tmp/hostname" <<'STUB'
#!/bin/sh
if [ -f "$BATS_TEST_TMPDIR/fake-hostname" ]; then
    cat "$BATS_TEST_TMPDIR/fake-hostname"
else
    echo "nix-builder"
fi
STUB
    chmod +x "$tmp/hostname"
    cat >"$tmp/avahi-publish" <<'STUB'
#!/bin/sh
echo "avahi-publish: $*"
STUB
    chmod +x "$tmp/avahi-publish"
}

@test "script is valid bash" {
    run bash -n fragments/avahi-alias-nix-serve.sh
    [ "$status" -eq 0 ]
}

@test "publishes nix-serve.local for nix-builder hostname" {
    echo "nix-builder" >"$BATS_TEST_TMPDIR/fake-hostname"
    cat >"$tmp/hostname" <<'STUB'
#!/bin/sh
if [ "$1" = "-I" ]; then echo "192.168.0.1"; else cat "$BATS_TEST_TMPDIR/fake-hostname"; fi
STUB
    chmod +x "$tmp/hostname"
    run env PATH="$tmp:$PATH" bash fragments/avahi-alias-nix-serve.sh
    [[ "${lines[*]}" =~ nix-serve\.local ]]
}

@test "publishes nix-serve-qemu.local for nix-builder-qemu hostname" {
    echo "nix-builder-qemu" >"$BATS_TEST_TMPDIR/fake-hostname"
    cat >"$tmp/hostname" <<'STUB'
#!/bin/sh
if [ "$1" = "-I" ]; then echo "10.0.2.15"; else cat "$BATS_TEST_TMPDIR/fake-hostname"; fi
STUB
    chmod +x "$tmp/hostname"
    run env PATH="$tmp:$PATH" bash fragments/avahi-alias-nix-serve.sh
    [[ "${lines[*]}" =~ nix-serve-qemu\.local ]]
}

@test "uses exec for long-running process" {
    run grep '^exec avahi-publish' fragments/avahi-alias-nix-serve.sh
    [ "$status" -eq 0 ]
}
