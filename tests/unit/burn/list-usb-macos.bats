#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/list-usb-macos.sh
  [ "$status" -eq 0 ]
}

@test "uses diskutil for device discovery" {
  grep -q 'diskutil' scripts/burn/list-usb-macos.sh
}

@test "outputs pipe-delimited device|size|model" {
  grep -q 'printf.*|.*|' scripts/burn/list-usb-macos.sh
}
