#!/usr/bin/env bats

@test "prints file contents when file exists" {
  tmp="$(mktemp)"
  echo -n "Europe/Warsaw" >"$tmp"
  run bash scripts/config/read-existing.sh "$tmp"
  [ "$status" -eq 0 ]
  [ "$output" = "Europe/Warsaw" ]
  rm -f "$tmp"
}

@test "prints nothing when file does not exist" {
  run bash scripts/config/read-existing.sh "/nonexistent/path"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
