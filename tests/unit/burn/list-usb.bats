#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/list-usb.sh
  [ "$status" -eq 0 ]
}

@test "supports fake backend via env" {
  grep -q 'NIX_BUILDER_BURN_FAKE_BACKEND' scripts/burn/list-usb.sh
}

@test "dispatches to platform-specific script" {
  grep -q 'list-usb-linux.sh' scripts/burn/list-usb.sh
  grep -q 'list-usb-macos.sh' scripts/burn/list-usb.sh
}

@test "exits 1 when no devices found" {
  tmp="$(mktemp)"
  : > "$tmp"
  run env NIX_BUILDER_BURN_FAKE_BACKEND="$tmp" bash scripts/burn/list-usb.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No USB" ]]
  rm -f "$tmp"
}

@test "prints devices from fake backend" {
  tmp="$(mktemp)"
  echo "/dev/sda|128G|Kingston" > "$tmp"
  run env NIX_BUILDER_BURN_FAKE_BACKEND="$tmp" bash scripts/burn/list-usb.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ /dev/sda ]]
  [[ "$output" =~ Kingston ]]
  rm -f "$tmp"
}
