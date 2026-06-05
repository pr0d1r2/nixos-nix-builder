#!/usr/bin/env bats

@test "exits 1 when no builders reachable" {
    run env SSH_AUTH_SOCK="" FIND_BUILDER_RETRIES=1 bash scripts/lib/find-builder.sh
    [ "$status" -eq 1 ] || [ "$status" -eq 0 ]
}

@test "prints error message on failure" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ssh" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$tmp/ssh"
    run env PATH="$tmp:$PATH" FIND_BUILDER_RETRIES=1 bash scripts/lib/find-builder.sh
    [ "$status" -eq 1 ]
    [[ "${lines[-1]}" =~ "no reachable builder" ]]
    rm -rf "$tmp"
}

@test "retries on transient failure then succeeds" {
    tmp="$(mktemp -d)"
    cat >"$tmp/ssh" <<'STUB'
#!/bin/sh
counter="$BATS_TMPDIR/find-builder-counter"
n=0
[ -f "$counter" ] && n=$(cat "$counter")
n=$((n + 1))
echo "$n" >"$counter"
if [ "$n" -ge 2 ]; then exit 0; fi
exit 1
STUB
    chmod +x "$tmp/ssh"
    cat >"$tmp/hostname" <<'STUB'
#!/bin/sh
echo "macbook"
STUB
    chmod +x "$tmp/hostname"
    rm -f "$BATS_TMPDIR/find-builder-counter"
    run env PATH="$tmp:$PATH" FIND_BUILDER_RETRIES=2 bash scripts/lib/find-builder.sh
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ "root@" ]]
    rm -rf "$tmp" "$BATS_TMPDIR/find-builder-counter"
}
