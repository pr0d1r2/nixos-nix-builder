# Changelog

## Unreleased

- Update all flake inputs (nix-lefthook-* from May 25 to June/July 2026, nixpkgs-lock to latest)
- Update GitHub Actions: checkout v4 to v7, create-pull-request v7 to v8, nix-lefthook-ci-action to latest SHA
- Remove stale flake override for renamed upstream input (nix-lefthook-bats-changed)
- Fix iso_store_dir test to sandbox filesystem access (failed on hosts with existing /mnt/storage)
- Add bats_require_minimum_version 1.5.0 to five test files using run flags

- Inject the QEMU serial console at runtime (qemu-cmd) so the ISO can stay clean (C24) -- fixes smoke after boot.nix dropped the baked console=
- Enable both Intel and AMD CPU microcode in the ISO so it works on T440p (Intel) and Ryzen (AMD) without changing the image
- Use NixOS default tmpfs size (50% RAM) instead of hardcoded 16G — fits 16 GB and 32 GB hosts alike
- Remove baked serial console from ISO kernel params; serial injected by QEMU at runtime only, bare metal boots to tty0
- Sweep stale smoke/boot QEMU workdirs on the builder before each run (they live on /mnt/storage, outside /nix/store, so the GC timer never reclaimed them and they grew unbounded); the sweep skips any workdir a live QEMU still has open, so a concurrent run is never disturbed

- Detach `just boot-remote` QEMU into a builder tmux session too (via qemu-remote-tmux), so a transient SSH drop no longer kills the boot guest mid-boot; nix-serve rides along for the guest cache

- Add qemu-remote-tmux helper: detach remote smoke QEMU into a builder tmux session so it survives transient SSH drops (serial streamed back with reconnect)
- Wire remote smoke onto the tmux-detach helper and power the guest off over SSH, ending the intermittent boot-time flake that forced re-runs
- Keep built ISOs on the builder instead of downloading 1.7G to the Mac each build; smoke, burn, and boot-remote all read the ISO from the builder store (remote-first, stops the Mac disk filling up)
- Link nix-config-example in README for client builder config
- Fix broken mermaid diagram in storage tier detection section
- Fix TDD order hook spec dir to match `tests/unit/` layout
- Add 9p host store health check to smoke tests (mountpoint + overlay lower layer)
- Fix nix-serve restart policy: `always` instead of `on-failure` to survive clean exits
- Share host nix store with QEMU guest via virtio-9p — guest reads host store paths as overlay lower layer without consuming disk
- Add periodic nix store GC: systemd timer runs daily at 03:00 UTC, triggers `nix-collect-garbage --delete-older-than 1d` when disk usage exceeds 80%, keeping 20% free for builds
- Add nix-store-gc timer health checks to smoke tests (schedule, persistence, non-destructive no-op run)

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
