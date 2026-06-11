#!/usr/bin/env bats

@test "exits 2 with wrong argument count" {
  run bash scripts/build/build-remote.sh
  [ "$status" -eq 2 ]
}

@test "script is valid bash" {
  run bash -n scripts/build/build-remote.sh
  [ "$status" -eq 0 ]
}

@test "stages the ISO in the builder store" {
  grep -q 'iso_store_dir.sh' scripts/build/build-remote.sh
}

@test "does not download the ISO back to this host" {
  run ! grep -q 'iso/.result' scripts/build/build-remote.sh
}
