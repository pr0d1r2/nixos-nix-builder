[private]
default:
    @just --list --list-prefix "    just "

# Boot ISO in QEMU locally (Linux x86_64 only).
boot:
    bash scripts/test-boot/boot-local.sh "$(pwd)" "$(ls -t iso/*.iso | head -1)" 2222

# Boot ISO in QEMU on remote builder.
boot-remote:
    bash scripts/test-boot/boot-remote.sh "$(pwd)" 2222 nix-builder.local

# Build ISO (skips if SHA already built).
build: config _build-or-skip

# Burn HEAD ISO to USB (skips if SHA already burned).
burn: _burn-build _smoke-or-skip _burn-auto-and-mark

# Burn HEAD ISO to USB, fully non-interactive (skips if SHA already burned).
burn-confirmed: _burn-build _smoke-or-skip _burn-confirmed-and-mark

# Configure user preferences (skips if complete).
config:
    bash scripts/config/ensure.sh

# Run health checks against live booted node.
live:
    bash scripts/live/live.sh

# Shut down live booted node.
poweroff:
    bash scripts/live/shutdown.sh

# Force rebuild ISO for current SHA.
rebuild: config
    bash scripts/build/build.sh

# Burn any ISO to USB (interactive, remote-first).
reburn:
    bash scripts/burn/reburn.sh

# Reconfigure all user preferences.
reconfig:
    bash scripts/config/configure.sh

# Force re-run QEMU smoke test for current SHA.
resmoke: build
    bash scripts/test-boot/test-boot.sh && bash scripts/test-boot/smoke-mark.sh

# QEMU smoke test (skips if SHA already passed).
smoke: build _smoke-or-skip

[private]
_burn-build: config
    bash scripts/build/build-for-burn.sh

[private]
_burn-auto-and-mark:
    bash scripts/burn/burn-check.sh || (bash scripts/burn/burn-auto.sh && bash scripts/burn/burn-mark.sh)

[private]
_burn-confirmed-and-mark:
    bash scripts/burn/burn-check.sh || (bash scripts/burn/burn-confirmed.sh && bash scripts/burn/burn-mark.sh)

[private]
_build-or-skip:
    bash scripts/build/build-check.sh || bash scripts/build/build.sh

[private]
_smoke-or-skip:
    bash scripts/test-boot/smoke-check.sh || (bash scripts/test-boot/test-boot.sh && bash scripts/test-boot/smoke-mark.sh)
