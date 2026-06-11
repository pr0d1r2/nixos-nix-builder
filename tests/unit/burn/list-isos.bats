#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/list-isos.sh
  [ "$status" -eq 0 ]
}

@test "exits 1 when directory does not exist" {
  run bash scripts/burn/list-isos.sh /nonexistent/path
  [ "$status" -eq 1 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "exits 1 when no ISOs in directory" {
  tmp="$(mktemp -d)"
  run bash scripts/burn/list-isos.sh "$tmp"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No ISOs" ]]
  rm -rf "$tmp"
}

@test "lists ISOs from directory" {
  tmp="$(mktemp -d)"
  touch "$tmp/a.iso" "$tmp/b.iso"
  run bash scripts/burn/list-isos.sh "$tmp"
  [ "$status" -eq 0 ]
  [[ "$output" =~ a\.iso ]]
  [[ "$output" =~ b\.iso ]]
  rm -rf "$tmp"
}
