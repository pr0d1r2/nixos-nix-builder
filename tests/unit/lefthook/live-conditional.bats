#!/usr/bin/env bats

@test "skips when node unreachable" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'EOF'
#!/bin/sh
exit 1
EOF
    cat >"$tmp/bash" <<'STUB'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in
        */ping-wait.sh) shift; exec sh "$tmp_dir/ping-wait.sh" "$@" ;;
    esac
done
exec /usr/bin/env bash "$@"
STUB
    chmod +x "$tmp/ping-wait.sh" "$tmp/bash"

    # Override ping-wait.sh by replacing REPO_ROOT resolution
    script="$(mktemp)"
    sed "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        scripts/lefthook/live-conditional.sh >"$script"

    run bash "$script"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "unreachable" ]]
    [[ "$output" =~ "skipping" ]]
    rm -rf "$tmp" "$script"
}

@test "runs expect when node reachable" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    cat >"$tmp/expect" <<'STUB'
#!/bin/sh
echo "expect-called $@"
exit 0
STUB
    chmod +x "$tmp/ping-wait.sh" "$tmp/expect"

    script="$(mktemp)"
    sed \
        -e "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        -e "s|expect \"\$REPO_ROOT/tests/integration/live.exp\"|\"$tmp/expect\" live.exp|" \
        scripts/lefthook/live-conditional.sh >"$script"

    run bash "$script"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "reachable" ]]
    [[ "$output" =~ "expect-called" ]]
    rm -rf "$tmp" "$script"
}

@test "respects NIX_BUILDER_HOST override" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'STUB'
#!/bin/sh
echo "ping-host:$1" >> "$BATS_TMPDIR/live-cond-args"
exit 1
STUB
    chmod +x "$tmp/ping-wait.sh"

    script="$(mktemp)"
    sed "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        scripts/lefthook/live-conditional.sh >"$script"

    rm -f "$BATS_TMPDIR/live-cond-args"
    run env NIX_BUILDER_HOST=custom-host.local bash "$script"
    [ "$status" -eq 0 ]
    grep -q "ping-host:custom-host.local" "$BATS_TMPDIR/live-cond-args"
    rm -f "$BATS_TMPDIR/live-cond-args"
    rm -rf "$tmp" "$script"
}
