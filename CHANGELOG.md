# Changelog

## Unreleased

### Storage

- Fix storage-link: add wants for mount services to guarantee symlink creation
- Use bind mount instead of symlink for /mnt/storage. Nix rejects symlinks in store paths; nix-store-overlay upper goes through /mnt/storage.

### Security

- USB block devices: udev grants builder user write access (no sudo for burn)
- Burn script: skip sudo when device already writable
- Reburn: remote-first, falls back to local when builder unreachable

### NixOS modules

- Firewall: explicit allow SSH (:22), nix-serve (:5000), mDNS (:5353)
- SSH hardening: MaxAuthTries=3, LoginGraceTime=30s, local forwarding only
- Boot: nomodeset + 1s timeout for appliance use
- Boot: GRUB menu shows ISO name with date+SHA version (no redundant NixOS prefix)
- Boot: force text mode GRUB for headless boot without monitor (isoImage.forceTextMode)
- Power: use logind.settings.Login (extraConfig deprecated)
- Power: allow power button shutdown (HandlePowerKey=poweroff)
- Skip nix-flake-check/eval hooks (secrets gitignored, pure eval incompatible)
- Users: mutableUsers=false, builder in kvm group
- Builder: sandbox=true, build-dir on /mnt/storage
- Avahi: dual mDNS -- nix-builder.local + nix-serve.local
- Avahi: derive nix-serve alias from hostname (nix-serve-qemu.local in QEMU)
- QEMU hostname override: boot as nix-builder-qemu to prevent mDNS cache poisoning
- Activation fixes: disable hashes script for locked-down users
- Module aggregator: flake.nix imports single ./modules path
- Power: disable sleep, suspend, hibernate, lid switch for 24/7 uptime

### QEMU smoke testing

- Full test-boot pipeline ported from nixos-poe2
- Expect-based serial console validation (Stage 1/2, services, storage)
- Direct kernel boot with serial console injection
- Configurable QEMU memory/CPU via QEMU_MEMORY/QEMU_SMP
- QEMU exit code interpreter
- Virtual NVMe + SATA drive creation for storage tests
- macOS remote testing via SSH to builder
- Standalone run-qemu.sh with baked QEMU binary path (no nix-shell at runtime)
- QEMU SSH forwarding bound to localhost (fixes ProxyJump through firewall)
- QEMU test work dir moved to /mnt/storage/tmp (saves 16G tmpfs for builds)
- QEMU test work dirs versioned by git SHA (no stale artifacts)
- Fix stale QEMU cleanup pattern for localhost-bound port forwarding

### Integration tests

- health-checks.tcl: extract shared checks from live.exp and smoke.exp
- smoke.exp: SSH health checks after serial boot (same checks as live)
- smoke.exp: skip hardware/network/mDNS checks in QEMU
- remote.tcl: ProxyJump support for Mac-to-QEMU-guest SSH
- ssh-wait.sh: fast-fail connectivity with ping + SSH exponential backoff (1s, 2s, 5s)
- ping-wait.sh: extract reusable ping backoff, wire into ssh-wait.sh
- live.exp: use ssh-wait.sh for fast-fail instead of 60s SSH loop
- smoke-conditional: pre-push runs QEMU smoke when builder reachable and not yet passed
- live-conditional: pre-push runs live.exp when node reachable, skips otherwise

### USB burn pipeline

- Interactive ISO + USB device selection
- Size sanity check before write
- Triple confirmation (type BURN to proceed)
- Progress bar via pv

### Developer tooling

- Lefthook upgraded to 2.1.8 via nix-lefthook
- 41 hook remotes (8 new: changelog-touched, linter-coverage-full, etc.)
- Unit tests migrated to tests/unit/ directory
- 82 bats tests covering all scripts and fragments
- Wire linter-coverage and unit-coverage pre-push hooks
- Add .unit-coverage.toml for automated test coverage checks

### Bug fixes

- qemu-hostname: use plain hostname command (hostnamectl blocked, /etc read-only), add inetutils to PATH, order after systemd-hostnamed, remove avahi restart deadlock
- find-builder: retry 3 times with 5s delay for mDNS re-resolution
- build-remote: commit rsync'd tree so flake sees valid rev (fixes epoch+dirty GRUB label)
- nix-store-overlay: stack disk-backed overlay directly (was stuck on 16G tmpfs, builds now use full disk)
- storage-link: force-replace /mnt/storage directory with symlink (nix daemon creates build-dir before link service)
- extract-kernel.sh: replace grep -P with portable sed (macOS compat)
- extract-kernel.sh: find bzImage/initrd in nix store paths, extract full cmdline
- build.sh: early exit on macOS when no builder reachable
- create-drives.sh: trap-based losetup cleanup on failure
- nix-store-overlay: guard bind-mount on rw-store existence
- storage-mount-target: use numeric uid:gid instead of username
- nix-serve: bind 0.0.0.0 for LAN access
- boot: mkForce timeout to override iso-image.nix default (10 → 1)

### Project

- Add MIT license
- Configure lefthook agentic output: no output on success, show only failures
- Configure new lefthook hooks (narrow-language, skill-registered, changelog-touched)
- Exclude LICENSE, config files, and SPEC.md from changelog-touched hook
- Skip unused narrow-language checks (ruby, python, js, ts, css, scss, erb, hcl, terraform)
- Fix ascii-only hook: use glob instead of exclude for reliable .md filtering
- Add CONTRIBUTING.md
- Add GitHub Actions CI via nix-lefthook-ci-action
- README: replace ASCII diagrams with mermaid
- README: add storage tier decision tree diagram
- README: add build pipeline diagram
- README: add NixOS module map diagram
- README: add CI and license badges
- README: add prerequisites section
- README: add network services port table
- README: add environment variables section
- README: add troubleshooting section
- README: add links footer
- README: add security hardening section
- README: add remote builder setup guide
- README: add QEMU guest cache discovery section
- README: add just commands reference table
- README: add boot sequence walkthrough
- README: add nix store overlay deep dive
- SPEC: add streamlined burn pipeline tasks (T55-T70)
- Gitignore smoke-passed and burn-done marker files
- Smoke recipe skips if SHA already passed, marks on success
- Add resmoke recipe for forced re-run of smoke test
- Add burn-check: skip burn if SHA already burned
- Add burn-mark: record successful burn with timestamp
- Add burn-auto: auto-select HEAD ISO for burning
- Burn supports NIX_BUILDER_BURN_AUTO and NIX_BUILDER_BURN_CONFIRMED env vars
- Burn auto/confirmed try remote builder first, fall back to local
- Burn remote: always pass HEAD SHA to builder, fix remote dir setup
- Add burn-confirmed: fully non-interactive burn pipeline
- Add burn-remote: burn ISO on builder over SSH, prefer fast storage
- Add burn recipe: smoke then auto-burn with skip-if-done
- Add burn-confirmed recipe: fully non-interactive burn pipeline
- Config ensure: run secrets setup before build
- Add skills: GNU tools (awk, coreutils, find, grep, sed)
- Add skills: lefthook (top-level, timeout, nix, sh, tdd, modularity)
- Add skill: linter coverage index for all file types
- Add skill: direnv reload and watch conventions
- Add skill: streamline (one just command per operation)
- Add skill: semble (semantic code search preference)
- Add skill: skill file organization (topic/aspect structure)
- Add skill: conditional pre-push hooks (gate on host reachability)
- Add skill: shared integration test health checks (.tcl lib)
- Add skill: lefthook glob subdirectory matching (**/*.ext)
- Add live integration test for booted node health checks (`just live`)
- Add `just live` recipe for post-burn node validation
- Add `just poweroff` recipe to shut down live booted node
- Add skill: architecture/remote/first (remote-first operations with Mac fallback)
- Add skill: QEMU cleanup (stale process and boot dir removal)
- Add skill: QEMU mDNS cache poisoning (flush after guest exit)
- Add skill: QEMU direct kernel boot (NixOS ISO layout)
- Register unregistered architecture skills in CLAUDE.md
- Add skill: language/anodyne (API-safe policy document writing)
- Add skill: language/concise (tight writing without meaning loss)
- Add skill: language/active (active voice over passive)
- Add skill: language/narrow (dictionary management for hooks)
- Add skill: language/imperative (imperative mood for commits and docs)
- Add skill: language/operator (write for operator, not developer)
- Burn recipes skip ISO download to Mac (ISO stays on builder)
- Smoke-remote prefers builder-staged ISO over local upload
- Smoke-remote: prefer system QEMU, fall back to nix-shell
- Smoke-remote: stop stale QEMU before boot to free port 2222
- Smoke-remote: clear stale boot dir before kernel extraction
- Smoke test: clear macOS mDNS cache after QEMU exits and wait for re-resolution
- Boot: add serial console params (console=ttyS0) for smoke tests
