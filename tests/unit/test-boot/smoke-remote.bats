#!/usr/bin/env bats

@test "script is valid bash" {
    run bash -n scripts/test-boot/smoke-remote.sh
    [ "$status" -eq 0 ]
}

@test "uses find-builder for discovery" {
    grep -q 'find-builder.sh' scripts/test-boot/smoke-remote.sh
}

@test "uses iso_store_dir for staging" {
    grep -q 'iso_store_dir.sh' scripts/test-boot/smoke-remote.sh
}

@test "runs QEMU via the tmux-detach helper" {
    grep -q 'qemu-remote-tmux.sh' scripts/test-boot/smoke-remote.sh
}

@test "does not run QEMU under a bare ssh -t" {
    run ! grep -q "ssh -t .*run-qemu.sh" scripts/test-boot/smoke-remote.sh
}
