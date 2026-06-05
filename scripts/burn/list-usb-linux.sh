#!/usr/bin/env bash
# Linux USB block-device enumerator.
# Output: <device>|<size>|<model>

set -Eeuo pipefail

busy_disks_file="$(mktemp)"
trap 'rm -f "$busy_disks_file"' EXIT

awk '$1 ~ "^/dev/" {
    src = $1
    sub("^/dev/", "", src)
    sub(/p?[0-9]+$/, "", src)
    print src
}' /proc/mounts >>"$busy_disks_file" 2>/dev/null || true

for loop_dir in /sys/block/loop*/loop; do
    [ -f "$loop_dir/backing_file" ] || continue
    bf="$(cat "$loop_dir/backing_file" 2>/dev/null || true)"
    [ -z "$bf" ] && continue
    src="$(df --output=source "$bf" 2>/dev/null | tail -n1)"
    [ -b "$src" ] || continue
    lsblk -nso NAME "$src" 2>/dev/null | tail -n1 | tr -d ' '
done >>"$busy_disks_file" 2>/dev/null || true

busy="$(sort -u "$busy_disks_file" | tr '\n' ' ')"

lsblk -d -n -p -b -o NAME,TRAN,SIZE,MODEL 2>/dev/null |
    awk -v busy="$busy" '
        BEGIN {
            n = split(busy, b, " ")
            for (i = 1; i <= n; i++) if (b[i] != "") busy_set[b[i]] = 1
        }
        $2 == "usb" {
            name = $1
            bare = name; sub("^/dev/", "", bare)
            if (bare in busy_set) next
            size = $3
            human = sprintf("%dG", size / 1024 / 1024 / 1024)
            $1=$1
            model = ""
            for (i = 4; i <= NF; i++) model = (model == "" ? $i : model " " $i)
            printf "%s|%s|%s\n", name, human, model
        }'
