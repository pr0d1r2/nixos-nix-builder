#!/usr/bin/env bats

@test "exits 0 when no SATA disks found" {
  tmp="$(mktemp -d)"
  cat >"$tmp/lsblk" <<'EOF'
#!/bin/sh
echo ""
EOF
  chmod +x "$tmp/lsblk"
  run env PATH="$tmp:$PATH" STORAGE_FSTYPE=ext4 bash -c '
        source fragments/storage-sata-mount.sh
    '
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "no non-USB" ]]
  rm -rf "$tmp"
}
