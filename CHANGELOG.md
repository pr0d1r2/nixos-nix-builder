# Changelog

## Unreleased

- Fix broken mermaid diagram in storage tier detection section
- Fix TDD order hook spec dir to match `tests/unit/` layout
- Fix nix-serve restart policy: `always` instead of `on-failure` to survive clean exits
- Share host nix store with QEMU guest via virtio-9p — guest reads host store paths as overlay lower layer without consuming disk

## 2026-06-05

### Storage

- NVMe > SATA tier detection with largest ext4 per tier
- Disk-backed nix store overlay (stacked overlay, ~458G vs 16G tmpfs)
- Bind mount /mnt/storage to fastest tier
- Storage-link uses wants for mount service ordering

### NixOS modules

- Headless boot: GRUB text mode (isoImage.forceTextMode), nomodeset, 1s timeout
- SSH hardening: key-only, MaxAuthTries=3, local TCP forwarding only
- Firewall: :22 (SSH), :5000 (nix-serve), :5353 (mDNS)
- nix-serve binary cache on :5000, signed, LAN-accessible (0.0.0.0)
- Avahi dual mDNS: nix-builder.local + nix-serve.local
- QEMU hostname override via kernel cmdline (ordered after systemd-hostnamed)
- QEMU nix cache injection via fw_cfg
- Power: disable sleep/suspend/hibernate, allow power button shutdown
- Builder: sandbox=true, build-dir on /mnt/storage, trusted-users
- Users: mutableUsers=false, builder in kvm/wheel/networkmanager groups
- USB udev: builder user write access to USB block devices
- Stable machine-id, AMD microcode, latest kernel

### QEMU smoke testing

- Full expect-based smoke pipeline (serial + SSH health checks)
- Direct kernel boot with serial console injection
- Virtual NVMe + SATA drives for storage tier testing
- macOS remote testing via SSH ProxyJump to builder
- SSH control socket mux for reliable health checks through ProxyJump
- QEMU SSH forwarding bound to localhost (bypasses firewall)
- Versioned work dirs on /mnt/storage by git SHA
- Configurable memory/CPU via QEMU_MEMORY/QEMU_SMP

### Integration tests

- Shared health-checks.tcl library (40+ checks, live + smoke reuse)
- Skip tags: hardware, network, mdns, boot (environment-specific)
- Fast-fail SSH with exponential backoff (ping + SSH, ≤16s)
- Conditional pre-push hooks: skip when host unreachable
- systemd boot wait (--wait) before health checks

### USB burn pipeline

- Interactive ISO + USB device selection with triple confirmation
- Remote-first burn (builder over SSH, local Mac fallback)
- Skip sudo when device writable (udev permissions)
- Size sanity check, progress bar via pv
- Skip-if-done markers by git SHA

### Developer tooling

- 45 bats test files covering all scripts and fragments
- 41 lefthook remotes (statix, deadnix, nixfmt, shellcheck, etc.)
- Linter coverage + unit coverage pre-push hooks
- Narrow-language vocabulary enforcement per file type
- Agentic output: silent on success, show only failures

### Project

- MIT license
- README with mermaid architecture diagrams
- SPEC.md (goals, constraints, interfaces, invariants)
- CONTRIBUTING.md
- GitHub Actions CI
