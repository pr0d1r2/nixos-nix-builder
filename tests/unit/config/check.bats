#!/usr/bin/env bats

@test "exits 0 when all settings present" {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/config/user"
  for s in timezone locale keymap fstype; do
    echo "test" >"$tmp/config/user/$s"
  done
  mkdir -p "$tmp/scripts/config"
  cp scripts/config/check.sh "$tmp/scripts/config/"
  run bash "$tmp/scripts/config/check.sh"
  [ "$status" -eq 0 ]
  rm -rf "$tmp"
}

@test "exits 1 when setting missing" {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/config/user"
  echo "test" >"$tmp/config/user/timezone"
  mkdir -p "$tmp/scripts/config"
  cp scripts/config/check.sh "$tmp/scripts/config/"
  run bash "$tmp/scripts/config/check.sh"
  [ "$status" -eq 1 ]
  rm -rf "$tmp"
}
