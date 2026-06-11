#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/burn/list-usb-linux.sh
  [ "$status" -eq 0 ]
}

@test "filters USB transport from lsblk" {
  grep -q 'usb' scripts/burn/list-usb-linux.sh
}

@test "excludes busy disks via /proc/mounts" {
  grep -q '/proc/mounts' scripts/burn/list-usb-linux.sh
}

@test "outputs pipe-delimited device|size|model" {
  grep -q 'printf.*|.*|' scripts/burn/list-usb-linux.sh
}
