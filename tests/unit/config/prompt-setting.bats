#!/usr/bin/env bats

@test "script exists and is valid bash" {
  run bash -n scripts/config/prompt-setting.sh
  [ "$status" -eq 0 ]
}
