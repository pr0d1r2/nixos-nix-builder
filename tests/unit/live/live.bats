#!/usr/bin/env bats
# Unit tests for scripts/live/live.sh

setup() {
  WORK_DIR="$(mktemp -d)"
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../../.." && pwd)"
  SCRIPT="$SCRIPT_DIR/scripts/live/live.sh"

  FAKE_BIN="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho "called expect $@"\nexit 0\n' >"$FAKE_BIN/expect"
  chmod +x "$FAKE_BIN/expect"
  export PATH="$FAKE_BIN:$PATH"
}

teardown() {
  rm -rf "$WORK_DIR" "$FAKE_BIN"
}

@test "runs expect with live.exp" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"live.exp"* ]]
}

@test "passes host argument to expect" {
  run bash "$SCRIPT" "custom-host.local"
  [ "$status" -eq 0 ]
  [[ "$output" == *"custom-host.local"* ]]
}

@test "passes host and port arguments to expect" {
  run bash "$SCRIPT" "custom-host.local" "2222"
  [ "$status" -eq 0 ]
  [[ "$output" == *"custom-host.local"* ]]
  [[ "$output" == *"2222"* ]]
}
