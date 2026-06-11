#!/usr/bin/env bats

@test "script is valid bash" {
  bash -n scripts/burn/reburn.sh
}

@test "tries remote first" {
  grep -q 'burn-remote.sh' scripts/burn/reburn.sh
}

@test "falls back to local burn on exit 2" {
  grep -q 'burn.sh' scripts/burn/reburn.sh
  grep -q 'rc.*eq 2' scripts/burn/reburn.sh
}
