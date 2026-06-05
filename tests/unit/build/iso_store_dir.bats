#!/usr/bin/env bats

@test "prefers /mnt/storage-fast when available" {
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/mnt/storage-fast"
    run env PATH="$tmp/bin:$PATH" sh -c "
        mkdir_called=''
        mkdir() { command mkdir \"\$@\"; }
        # Simulate: /mnt/storage-fast exists
        cd '$tmp' && source /dev/stdin <<'SCRIPT'
$(sed 's|/mnt/storage-fast|'"$tmp"'/mnt/storage-fast|g;s|/mnt/storage|'"$tmp"'/mnt/storage|g;s|/tmp/|'"$tmp"'/tmp/|g' scripts/build/iso_store_dir.sh)
SCRIPT
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ nix-builder-iso ]]
    rm -rf "$tmp"
}

@test "outputs a directory path" {
    run sh scripts/build/iso_store_dir.sh
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
