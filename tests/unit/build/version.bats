#!/usr/bin/env bats

@test "produces canonical ISO filename" {
  run bash scripts/build/version.sh 25.11 20260511 1430 abcdef1234567 x86_64 linux
  [ "$status" -eq 0 ]
  [ "$output" = "nixos-nix-builder-25.11-20260511-1430-abcdef1-x86_64-linux.iso" ]
}

@test "truncates SHA to 7 characters" {
  run bash scripts/build/version.sh 25.11 20260511 1430 1234567890abcdef x86_64 linux
  [ "$status" -eq 0 ]
  [[ "$output" =~ -1234567- ]]
}

@test "exits 2 with too few arguments" {
  run bash scripts/build/version.sh 25.11 20260511
  [ "$status" -eq 2 ]
}

@test "exits 2 with no arguments" {
  run bash scripts/build/version.sh
  [ "$status" -eq 2 ]
}
