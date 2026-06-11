#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/burn-auto.sh
  [ "$status" -eq 0 ]
}

@test "sets NIX_BUILDER_BURN_AUTO=1" {
  run grep -q 'NIX_BUILDER_BURN_AUTO=1' scripts/burn/burn-auto.sh
  [ "$status" -eq 0 ]
}

@test "tries remote first" {
  grep -q 'burn-remote.sh' scripts/burn/burn-auto.sh
}

@test "falls back to local burn" {
  grep -q 'burn.sh' scripts/burn/burn-auto.sh
}
