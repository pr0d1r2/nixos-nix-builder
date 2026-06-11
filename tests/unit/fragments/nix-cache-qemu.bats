#!/usr/bin/env bats

@test "exits 0 on real hardware (no fw_cfg)" {
  tmp="$(mktemp -d)"
  cat >"$tmp/modprobe" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp/modprobe"
  run env PATH="$tmp:$PATH" bash -c '
        sed "s|/sys/firmware/qemu_fw_cfg/by_name/opt/nixos-nix-builder/nix_cache_url/raw|/nonexistent/fw_cfg|g" fragments/nix-cache-qemu.sh | bash
    '
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "no fw_cfg" ]]
  rm -rf "$tmp"
}
