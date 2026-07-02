#!/usr/bin/env bats

setup() {
    WORK_DIR="$(mktemp -d)"
    FAKE_BIN="$(mktemp -d)"
    printf '#!/usr/bin/env bash\n' >"$FAKE_BIN/qemu-system-x86_64"
    chmod +x "$FAKE_BIN/qemu-system-x86_64"
    export PATH="$FAKE_BIN:$PATH"
}

teardown() {
    rm -rf "$WORK_DIR" "$FAKE_BIN"
}

@test "exits 2 with no arguments" {
    run bash scripts/test-boot/qemu-cmd.sh
    [ "$status" -eq 2 ]
}

@test "exits 2 with too many arguments" {
    run bash scripts/test-boot/qemu-cmd.sh a b c d
    [ "$status" -eq 2 ]
}

@test "writes run-qemu.sh with ISO path" {
    run bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    [ "$status" -eq 0 ]
    [ -f "$WORK_DIR/run-qemu.sh" ]
    grep -q 'qemu-system-x86_64' "$WORK_DIR/run-qemu.sh"
    grep -q '/tmp/test.iso' "$WORK_DIR/run-qemu.sh" # nolocalpath
}

@test "includes SSH port forwarding" {
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q 'hostfwd=tcp:127.0.0.1:2222-:22' "$WORK_DIR/run-qemu.sh"
}

@test "uses virtio-net-pci" {
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q 'virtio-net-pci' "$WORK_DIR/run-qemu.sh"
}

@test "includes fw_cfg entries" {
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q 'opt/nixos-nix-builder/nix_cache_url' "$WORK_DIR/run-qemu.sh"
    grep -q 'opt/nixos-nix-builder/fw_test_gw' "$WORK_DIR/run-qemu.sh"
}

@test "uses direct kernel boot when boot-dir provided" {
    mkdir -p "$WORK_DIR/boot"
    echo "test" >"$WORK_DIR/boot/bzImage"
    echo "test" >"$WORK_DIR/boot/initrd"
    echo "init=/nix/store/xxx/init boot.shell_on_fail root=LABEL=nixos-minimal-25.11-x86_64 console=ttyS0,115200" >"$WORK_DIR/boot/cmdline"
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" "$WORK_DIR/boot" # nolocalpath
    grep -q '\-kernel' "$WORK_DIR/run-qemu.sh"
    grep -q '\-initrd' "$WORK_DIR/run-qemu.sh"
    grep -q 'root=LABEL=' "$WORK_DIR/run-qemu.sh"
    grep -q 'console=ttyS0' "$WORK_DIR/run-qemu.sh"
}

@test "uses GRUB boot when no boot-dir" {
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q '\-boot d' "$WORK_DIR/run-qemu.sh"
}

@test "uses custom memory when QEMU_MEMORY set" {
    QEMU_MEMORY="8G" bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q '\-m 8G' "$WORK_DIR/run-qemu.sh"
}

@test "uses custom SMP when QEMU_SMP set" {
    QEMU_SMP="4" bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q '\-smp 4' "$WORK_DIR/run-qemu.sh"
}

@test "shares host nix store via virtio-9p" {
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q 'virtfs local,path=/nix/store,mount_tag=nix-host-store,security_model=none,readonly=on' "$WORK_DIR/run-qemu.sh"
}

@test "bakes full QEMU binary path" {
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" # nolocalpath
    grep -q '/.*qemu-system-x86_64' "$WORK_DIR/run-qemu.sh"
}

@test "injects serial console at runtime when cmdline lacks it (C24)" {
    boot="$WORK_DIR/boot"
    mkdir -p "$boot"
    : >"$boot/bzImage"
    : >"$boot/initrd"
    # clean-ISO cmdline with no console= (extract-kernel output)
    echo "init=/x/init root=LABEL=foo nomodeset loglevel=4" >"$boot/cmdline"
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" "$boot" # nolocalpath
    grep -q 'console=ttyS0,115200' "$WORK_DIR/run-qemu.sh"
}

@test "does not duplicate console= when cmdline already has it" {
    boot="$WORK_DIR/boot"
    mkdir -p "$boot"
    : >"$boot/bzImage"
    : >"$boot/initrd"
    echo "init=/x/init console=tty0 console=ttyS0,115200n8 loglevel=4" >"$boot/cmdline"
    bash scripts/test-boot/qemu-cmd.sh /tmp/test.iso "$WORK_DIR" "$boot" # nolocalpath
    [ "$(grep -o 'console=ttyS0' "$WORK_DIR/run-qemu.sh" | wc -l)" -eq 1 ]
}
