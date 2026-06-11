#!/usr/bin/env bats
# Coverage for scripts/test-boot/qemu-remote-tmux.sh. The happy path
# detaches QEMU in a builder tmux session and streams its serial back
# with reconnect, which needs nix-builder.local; bats pins only the
# observable offline surface (parse, argument validation, design
# invariants) without driving the network.

SCRIPT="scripts/test-boot/qemu-remote-tmux.sh"

@test "script is valid bash" {
  run bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "fails without arguments" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "fails when required args are missing" {
  run bash "$SCRIPT" root@builder some-session
  [ "$status" -ne 0 ]
}

@test "detaches QEMU into a tmux session" {
  grep -q 'tmux' "$SCRIPT"
  grep -q 'new-session -d' "$SCRIPT"
}

@test "uses a dedicated tmux socket per session" {
  grep -q 'tmux -S' "$SCRIPT"
}

@test "captures serial via pipe-pane to a logfile" {
  grep -q 'pipe-pane' "$SCRIPT"
}

@test "holds the -L port forward for health checks" {
  grep -q 'ssh -L' "$SCRIPT"
}

@test "returns the guest exit code via an rc file" {
  grep -q 'rcfile' "$SCRIPT"
}

@test "reconnects in a loop until the guest exits" {
  grep -q 'while true' "$SCRIPT"
}

@test "reaps the detached guest on its own exit" {
  grep -q 'trap' "$SCRIPT"
  grep -q 'pkill -f' "$SCRIPT"
}
