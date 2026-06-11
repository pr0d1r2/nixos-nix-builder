#!/usr/bin/env bats

setup() {
  tmp="$(mktemp -d)"
  fake_cmdline="$tmp/cmdline"
  fake_fw_cfg="$tmp/fw_cfg_raw"
  cat >"$tmp/hostname" <<'STUB'
#!/bin/sh
echo "hostname: $*" >&2
STUB
  chmod +x "$tmp/hostname"
  cat >"$tmp/systemctl" <<'STUB'
#!/bin/sh
echo "systemctl: $*" >&2
STUB
  chmod +x "$tmp/systemctl"
  cat >"$tmp/modprobe" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$tmp/modprobe"
}

teardown() {
  rm -rf "$tmp"
}

run_fragment() {
  env PATH="$tmp:$PATH" bash -c "
        sed -e 's|/proc/cmdline|$fake_cmdline|g' \
            -e 's|/sys/firmware/qemu_fw_cfg/by_name/opt/nixos-nix-builder/hostname/raw|$fake_fw_cfg|g' \
            -e 's|/etc/hostname|$tmp/etc-hostname|g' \
            fragments/qemu-hostname.sh | bash
    "
}

@test "skips when no cmdline param and no fw_cfg" {
  echo "root=LABEL=nixos init=/nix/store/xxx/init loglevel=4" >"$fake_cmdline"
  rm -f "$fake_fw_cfg"
  run run_fragment
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "no hostname override" ]]
}

@test "sets hostname from kernel cmdline" {
  echo "root=LABEL=nixos nixbuilder.hostname=nix-builder-test init=/nix/store/xxx/init" >"$fake_cmdline"
  rm -f "$fake_fw_cfg"
  run run_fragment
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "nix-builder-test" ]]
}

@test "ignores empty nixbuilder.hostname" {
  echo "root=LABEL=nixos nixbuilder.hostname= init=/nix/store/xxx/init" >"$fake_cmdline"
  rm -f "$fake_fw_cfg"
  run run_fragment
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "no hostname override" ]]
}

@test "falls back to fw_cfg when cmdline has no param" {
  echo "root=LABEL=nixos init=/nix/store/xxx/init" >"$fake_cmdline"
  echo -n "nix-builder-qemu" >"$fake_fw_cfg"
  run run_fragment
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "nix-builder-qemu" ]]
}

@test "cmdline takes priority over fw_cfg" {
  echo "root=LABEL=nixos nixbuilder.hostname=from-cmdline init=/nix/store/xxx/init" >"$fake_cmdline"
  echo -n "from-fwcfg" >"$fake_fw_cfg"
  run run_fragment
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "from-cmdline" ]]
  [[ ! "${lines[*]}" =~ "from-fwcfg" ]]
}
