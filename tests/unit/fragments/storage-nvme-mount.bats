#!/usr/bin/env bats

@test "exits 0 when no NVMe found" {
    tmp="$(mktemp -d)"
    cat >"$tmp/lsblk" <<'EOF'
#!/bin/sh
echo ""
EOF
    chmod +x "$tmp/lsblk"
    run env PATH="$tmp:$PATH" STORAGE_FSTYPE=ext4 bash -c '
        source fragments/storage-nvme-mount.sh
    '
    [ "$status" -eq 0 ]
    rm -rf "$tmp"
}

@test "reports skipped non-ext4 partitions" {
    tmp="$(mktemp -d)"
    cat >"$tmp/lsblk" <<'MOCK'
#!/bin/sh
echo "/dev/nvme0n1p1 part 107374182400 ntfs /dev/nvme0n1"
MOCK
    chmod +x "$tmp/lsblk"
    run env PATH="$tmp:$PATH" STORAGE_FSTYPE=ext4 bash -c '
        source fragments/storage-nvme-mount.sh
    '
    [ "$status" -eq 0 ]
    [[ "$output" =~ "no ext4 partition" ]] || [[ "${lines[*]}" =~ "nothing to mount" ]]
    rm -rf "$tmp"
}
