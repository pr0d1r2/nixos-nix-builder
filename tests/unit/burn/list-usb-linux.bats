#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n scripts/burn/list-usb-linux.sh
    [ "$status" -eq 0 ]
}

@test "uses lsblk for device enumeration" {
    grep -q 'lsblk' scripts/burn/list-usb-linux.sh
}

@test "filters for USB transport" {
    grep -q 'usb' scripts/burn/list-usb-linux.sh
}

@test "excludes mounted disks" {
    grep -q '/proc/mounts' scripts/burn/list-usb-linux.sh
}

@test "output format is pipe-delimited" {
    grep -q 'printf.*|.*|' scripts/burn/list-usb-linux.sh
}
