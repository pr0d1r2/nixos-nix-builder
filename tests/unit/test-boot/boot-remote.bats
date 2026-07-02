#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

@test "exits 2 with wrong argument count" {
    run bash scripts/test-boot/boot-remote.sh
    [ "$status" -eq 2 ]
}

@test "exits 2 with too few arguments" {
    run bash scripts/test-boot/boot-remote.sh /tmp 2222
    [ "$status" -eq 2 ]
}

@test "reads ISO from the builder store" {
    grep -q 'iso_store_dir.sh' scripts/test-boot/boot-remote.sh
}

@test "does not upload an ISO to the builder" {
    run ! grep -q 'rsync.*\.iso' scripts/test-boot/boot-remote.sh
}

@test "boots QEMU via the tmux-detach helper" {
    grep -q 'qemu-remote-tmux.sh' scripts/test-boot/boot-remote.sh
}

@test "does not run QEMU under a bare ssh -t" {
    run ! grep -q 'ssh -t' scripts/test-boot/boot-remote.sh
}

@test "skips the workdir sweep when a live QEMU has it open" {
    grep -q "pgrep -af qemu-system-x86_64 | grep -qF '\$WORK_DIR' || rm -rf" scripts/test-boot/boot-remote.sh
}

@test "passes nix-serve to the helper for the guest cache" {
    grep -q 'boot-run.sh" "nix-serve"' scripts/test-boot/boot-remote.sh
}
