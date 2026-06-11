#!/usr/bin/env bats

@test "fails with no arguments" {
  run bash scripts/lib/ssh-wait.sh
  [ "$status" -ne 0 ]
}

@test "fails when ping fails" {
  tmp="$(mktemp -d)"
  cat >"$tmp/ping" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$tmp/ping"
  run env PATH="$tmp:$PATH" bash scripts/lib/ssh-wait.sh unreachable-host
  [ "$status" -eq 1 ]
  [[ "$output" =~ "ping failed" ]]
  rm -rf "$tmp"
}

@test "fails when ping succeeds but SSH fails" {
  tmp="$(mktemp -d)"
  cat >"$tmp/ping" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$tmp/ssh" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$tmp/ping" "$tmp/ssh"
  run env PATH="$tmp:$PATH" bash scripts/lib/ssh-wait.sh test-host
  [ "$status" -eq 1 ]
  [[ "$output" =~ "SSH unreachable" ]]
  rm -rf "$tmp"
}

@test "succeeds when ping and SSH succeed" {
  tmp="$(mktemp -d)"
  cat >"$tmp/ping" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$tmp/ssh" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp/ping" "$tmp/ssh"
  run env PATH="$tmp:$PATH" bash scripts/lib/ssh-wait.sh test-host
  [ "$status" -eq 0 ]
  rm -rf "$tmp"
}

@test "passes port and user to SSH" {
  tmp="$(mktemp -d)"
  cat >"$tmp/ping" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat >"$tmp/ssh" <<'STUB'
#!/bin/sh
echo "$@" >> "$BATS_TMPDIR/ssh-wait-args"
exit 0
STUB
  chmod +x "$tmp/ping" "$tmp/ssh"
  rm -f "$BATS_TMPDIR/ssh-wait-args"
  run env PATH="$tmp:$PATH" bash scripts/lib/ssh-wait.sh myhost 2222 myuser
  [ "$status" -eq 0 ]
  grep -q "2222" "$BATS_TMPDIR/ssh-wait-args"
  grep -q "myuser@myhost" "$BATS_TMPDIR/ssh-wait-args"
  rm -f "$BATS_TMPDIR/ssh-wait-args"
  rm -rf "$tmp"
}

@test "retries ping with exponential backoff" {
  tmp="$(mktemp -d)"
  cat >"$tmp/ping" <<'STUB'
#!/bin/sh
counter="$BATS_TMPDIR/ssh-wait-ping-counter"
n=0
[ -f "$counter" ] && n=$(cat "$counter")
n=$((n + 1))
echo "$n" >"$counter"
if [ "$n" -ge 2 ]; then exit 0; fi
exit 1
STUB
  cat >"$tmp/ssh" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp/ping" "$tmp/ssh"
  rm -f "$BATS_TMPDIR/ssh-wait-ping-counter"
  run env PATH="$tmp:$PATH" bash scripts/lib/ssh-wait.sh test-host
  [ "$status" -eq 0 ]
  rm -f "$BATS_TMPDIR/ssh-wait-ping-counter"
  rm -rf "$tmp"
}
