#!/usr/bin/env bats
# Coverage for scripts/test-boot/boot-run.sh. It starts nix-serve and
# runs the QEMU launch script inside the detached tmux session; the live
# path needs the builder, so bats pins the offline surface (parse, design
# invariants) without driving QEMU.

SCRIPT="scripts/test-boot/boot-run.sh"

@test "script is valid bash" {
  run bash -n "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "starts the guest binary cache (nix-serve)" {
  grep -q 'nix-serve -p 5000' "$SCRIPT"
}

@test "frees a stale :5000 binding first" {
  grep -q 'fuser -k 5000/tcp' "$SCRIPT"
}

@test "runs the generated run-qemu.sh" {
  grep -q 'run-qemu.sh' "$SCRIPT"
}

@test "self-locates the work dir from its own path" {
  grep -q 'BASH_SOURCE' "$SCRIPT"
}

@test "returns QEMU's exit code" {
  # shellcheck disable=SC2016  # literal match of the script's `exit "$rc"`
  grep -q 'exit "$rc"' "$SCRIPT"
}
