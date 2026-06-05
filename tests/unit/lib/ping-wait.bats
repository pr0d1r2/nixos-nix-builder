#!/usr/bin/env bats

@test "fails with no arguments" {
    run bash scripts/lib/ping-wait.sh
    [ "$status" -ne 0 ]
}

@test "fails when ping fails all retries" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$tmp/ping"
    run env PATH="$tmp:$PATH" bash scripts/lib/ping-wait.sh unreachable-host
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ping failed" ]]
    rm -rf "$tmp"
}

@test "succeeds when ping succeeds on first try" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$tmp/ping"
    run env PATH="$tmp:$PATH" bash scripts/lib/ping-wait.sh test-host
    [ "$status" -eq 0 ]
    rm -rf "$tmp"
}

@test "retries with exponential backoff" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping" <<'STUB'
#!/bin/sh
counter="$BATS_TMPDIR/ping-wait-counter"
n=0
[ -f "$counter" ] && n=$(cat "$counter")
n=$((n + 1))
echo "$n" >"$counter"
if [ "$n" -ge 2 ]; then exit 0; fi
exit 1
STUB
    chmod +x "$tmp/ping"
    rm -f "$BATS_TMPDIR/ping-wait-counter"
    run env PATH="$tmp:$PATH" bash scripts/lib/ping-wait.sh test-host
    [ "$status" -eq 0 ]
    rm -f "$BATS_TMPDIR/ping-wait-counter"
    rm -rf "$tmp"
}

@test "passes timeout to ping -W flag" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping" <<'STUB'
#!/bin/sh
echo "$@" >> "$BATS_TMPDIR/ping-wait-args"
exit 0
STUB
    chmod +x "$tmp/ping"
    rm -f "$BATS_TMPDIR/ping-wait-args"
    run env PATH="$tmp:$PATH" bash scripts/lib/ping-wait.sh test-host
    [ "$status" -eq 0 ]
    grep -q "\-W" "$BATS_TMPDIR/ping-wait-args"
    rm -f "$BATS_TMPDIR/ping-wait-args"
    rm -rf "$tmp"
}
