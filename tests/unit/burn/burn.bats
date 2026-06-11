#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/burn.sh
  [ "$status" -eq 0 ]
}

@test "exits 1 when no ISOs exist" {
  TEST_DIR="$(mktemp -d)"
  mkdir -p "$TEST_DIR/scripts/burn" "$TEST_DIR/iso"
  cp scripts/burn/burn.sh "$TEST_DIR/scripts/burn/"
  cp scripts/burn/list-isos.sh "$TEST_DIR/scripts/burn/"
  cp scripts/burn/list-usb.sh "$TEST_DIR/scripts/burn/"
  cd "$TEST_DIR" || return
  run bash "$TEST_DIR/scripts/burn/burn.sh" "$TEST_DIR/iso"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No ISOs" ]]
  rm -rf "$TEST_DIR"
}

@test "list-isos script is valid bash" {
  run bash -n scripts/burn/list-isos.sh
  [ "$status" -eq 0 ]
}

@test "list-usb script is valid bash" {
  run bash -n scripts/burn/list-usb.sh
  [ "$status" -eq 0 ]
}

@test "list-usb-linux script is valid bash" {
  run bash -n scripts/burn/list-usb-linux.sh
  [ "$status" -eq 0 ]
}

@test "list-usb-macos script is valid bash" {
  run bash -n scripts/burn/list-usb-macos.sh
  [ "$status" -eq 0 ]
}
