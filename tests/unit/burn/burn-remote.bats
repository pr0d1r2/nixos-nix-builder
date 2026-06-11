#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/burn-remote.sh
  [ "$status" -eq 0 ]
}

@test "exits 2 when NIX_BUILDER_BURN_LOCAL=1" {
  export NIX_BUILDER_BURN_LOCAL=1
  run bash scripts/burn/burn-remote.sh
  [ "$status" -eq 2 ]
  [[ "$output" =~ "local-only" ]]
}

@test "uses find-builder.sh for discovery" {
  run grep -q 'find-builder.sh' scripts/burn/burn-remote.sh
  [ "$status" -eq 0 ]
}

@test "propagates auto and confirmed flags" {
  run grep -q 'NIX_BUILDER_BURN_AUTO' scripts/burn/burn-remote.sh
  [ "$status" -eq 0 ]
  run grep -q 'NIX_BUILDER_BURN_CONFIRMED' scripts/burn/burn-remote.sh
  [ "$status" -eq 0 ]
}

@test "resolves ISO dir on builder" {
  grep -q 'iso_store_dir.sh' scripts/burn/burn-remote.sh
}

@test "passes ISO dir to burn.sh" {
  grep -q "burn.sh '\$ISO_DIR'" scripts/burn/burn-remote.sh
}
