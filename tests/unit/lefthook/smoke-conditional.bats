#!/usr/bin/env bats

@test "skips when builder unreachable" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$tmp/ping-wait.sh"

    script="$(mktemp)"
    sed "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        scripts/lefthook/smoke-conditional.sh >"$script"

    run bash "$script"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "unreachable" ]]
    [[ "$output" =~ "skipping" ]]
    rm -rf "$tmp" "$script"
}

@test "skips when smoke already passed" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    cat >"$tmp/smoke-check.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$tmp/ping-wait.sh" "$tmp/smoke-check.sh"

    script="$(mktemp)"
    sed \
        -e "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        -e "s|bash \"\$REPO_ROOT/scripts/test-boot/smoke-check.sh\"|bash \"$tmp/smoke-check.sh\"|" \
        scripts/lefthook/smoke-conditional.sh >"$script"

    run bash "$script"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already passed" ]]
    [[ "$output" =~ "skipping" ]]
    rm -rf "$tmp" "$script"
}

@test "runs smoke when builder reachable and not passed" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    cat >"$tmp/smoke-check.sh" <<'EOF'
#!/bin/sh
exit 1
EOF
    cat >"$tmp/test-boot.sh" <<'EOF'
#!/bin/sh
echo "test-boot-called"
exit 0
EOF
    cat >"$tmp/smoke-mark.sh" <<'EOF'
#!/bin/sh
echo "smoke-mark-called"
exit 0
EOF
    chmod +x "$tmp/ping-wait.sh" "$tmp/smoke-check.sh" "$tmp/test-boot.sh" "$tmp/smoke-mark.sh"

    script="$(mktemp)"
    sed \
        -e "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        -e "s|bash \"\$REPO_ROOT/scripts/test-boot/smoke-check.sh\"|bash \"$tmp/smoke-check.sh\"|" \
        -e "s|bash \"\$REPO_ROOT/scripts/test-boot/test-boot.sh\"|bash \"$tmp/test-boot.sh\"|" \
        -e "s|bash \"\$REPO_ROOT/scripts/test-boot/smoke-mark.sh\"|bash \"$tmp/smoke-mark.sh\"|" \
        scripts/lefthook/smoke-conditional.sh >"$script"

    run bash "$script"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-boot-called" ]]
    [[ "$output" =~ "smoke-mark-called" ]]
    rm -rf "$tmp" "$script"
}

@test "respects NIX_BUILDER_HOST override" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ping-wait.sh" <<'STUB'
#!/bin/sh
echo "ping-host:$1" >> "$BATS_TMPDIR/smoke-cond-args"
exit 1
STUB
    chmod +x "$tmp/ping-wait.sh"

    script="$(mktemp)"
    sed "s|bash \"\$REPO_ROOT/scripts/lib/ping-wait.sh\"|bash \"$tmp/ping-wait.sh\"|" \
        scripts/lefthook/smoke-conditional.sh >"$script"

    rm -f "$BATS_TMPDIR/smoke-cond-args"
    run env NIX_BUILDER_HOST=custom-host.local bash "$script"
    [ "$status" -eq 0 ]
    grep -q "ping-host:custom-host.local" "$BATS_TMPDIR/smoke-cond-args"
    rm -f "$BATS_TMPDIR/smoke-cond-args"
    rm -rf "$tmp" "$script"
}
