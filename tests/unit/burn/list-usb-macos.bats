#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n scripts/burn/list-usb-macos.sh
    [ "$status" -eq 0 ]
}

@test "uses diskutil for device enumeration" {
    grep -q 'diskutil' scripts/burn/list-usb-macos.sh
}

@test "filters for external physical disks" {
    grep -q 'external physical' scripts/burn/list-usb-macos.sh
}

@test "output format is pipe-delimited" {
    grep -q 'printf.*|.*|' scripts/burn/list-usb-macos.sh
}
