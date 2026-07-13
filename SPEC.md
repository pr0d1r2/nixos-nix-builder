# SPEC — nixos-nix-builder

## §G GOAL

Bootable NixOS USB pendrive. Turns any modern x86_64 host into headless nix builder appliance. SSH + nix-serve binary cache on :5000 + QEMU for ISO smoke testing. Stick stateless — nix store overlaid onto host's largest ext4 partition. Primary consumer: nixos-poe2.

## §C CONSTRAINTS

- C1: NixOS flake, minimal installer ISO base (`installation-cd-minimal.nix`), pinned `nixos-25.11`
- C2: headless — no X11, no GPU driver, no desktop, no display manager
- C3: target = any modern x86_64 host w/ enough resources (references: T440p low-end 4c/8t 16 GB | Ryzen 3800X mid-range 8c/16t 32 GB); microcode auto per CPU (C36) — superseded by C35
- C4: storage tiers: NVMe > SATA, largest ext4 wins per tier, symlinked `/mnt/storage`
- C4a: no USB storage — pendrive stateless, ⊥ game/build storage
- C5: nix store overlay ! redirect tmpfs → disk — host RAM stays free for builds
- C6: nix-serve on :5000, always-on, LAN-accessible (`0.0.0.0`) — binary cache for remote builds & QEMU guests
- C6a: nix-serve reachable via `nix-builder.local:5000` & `nix-serve.local:5000` (dual mDNS CNAME)
- C7: QEMU w/ KVM — smoke test ISOs (own + nixos-poe2 + future projects)
- C7a: fw_cfg namespace `opt/nixos-nix-builder/` — guest ISOs auto-discover cache
- C7b: virtio-net-pci — avoids e1000 "Detected Tx Unit Hang" stalls
- C8: SSH server, key-only auth, keys baked from `secrets/authorized_keys`
- C9: Avahi mDNS — discoverable as `nix-builder.local`
- C10: `linuxPackages_latest` kernel
- C11: build on macOS via existing builder | self-build on x86_64-linux
- C12: shell scripts: no functions, extract to separate scripts, prepend `bash`
- C13: nix modules: no embedded shell, extract to `fragments/`
- C14: TDD — ∀ implementation file covered 1-to-1 w/ bats unit test
- C15: justfile lowercase, default lists all, alpha order, extract shell to scripts
- C16: portable dev tooling — macOS (dev) + Linux (build/run)
- C17: ⊥ credentials | personal data in repo | ISO
- C18: `trusted-users = root builder` — remote flake builds accepted
- C19: `max-jobs = auto; cores = 0` — saturate all cores
- C20: stable machine-id across boots — deterministic from `echo -n "nixos-nix-builder" | md5sum`
- C21: locale/keymap/timezone configurable at build time via `config/user/` files
- C22: flake.lock committed — reproducible builds
- C23: NTP time sync enabled
- C24: direct kernel boot in QEMU — inject `console=ttyS0` at runtime, ISO stays clean
- C25: SSH hardened: MaxAuthTries=3, LoginGraceTime=30s, ⊥ TCP/agent forwarding
- C26: nix `sandbox = true` — builds isolated
- C27: serial console: inject via QEMU only, bare metal disabled (`nomodeset`, ⊥ serial-getty)
- C28: QEMU memory/CPU configurable via `QEMU_MEMORY` & `QEMU_SMP` env vars
- C29: builder user ∈ kvm group — QEMU/KVM guest access
- C30: `users.mutableUsers = false` — declarative user provisioning only, ⊥ runtime edits
- C31: boot timeout 1s — appliance, ⊥ menu browsing
- C32: nix `build-dir` on `/mnt/storage` — large builds ⊥ exhaust the `/tmp` tmpfs
- C33: `system.activationScripts.hashes` disabled — breaks w/ `mutableUsers=false` locked-down config
- C34: firewall LAN-only: :5000 + :22 open to local network, ⊥ WAN exposure
- C35: builder = any modern x86_64 host w/ enough resources — references T440p (low-end, Intel Haswell 4c/8t, 16 GB) | Ryzen 3800X (mid-range, 8c/16t, 32 GB); single `nix-builder.local` (one machine at a time, ⊥ both at once), consumers size to it (supersedes C3). External `nix.buildMachines` configs target the stable `nix-builder.local` unchanged
- C36: both CPU microcodes in initrd — `hardware.cpu.{intel,amd}.updateMicrocode` (redistributable firmware, NixOS handles it, ⊥ `allowUnfree`); kernel early-loader auto-applies the matching vendor (Intel | AMD), ⊥ AMD-only
- C37: guest QEMU sized to builder by direct passthrough — `mem` = `memgb` (ceil of MemTotal to GB — matches the advertised laptop size, e.g. 15.57→16), `cpus` = nproc (all cores); store ⊥ a guest knob; ⊥ formulas, ⊥ hardcoded 16G/8 (KVM `-m` demand-paged, light guests never claim it all)
- C38: builder tmpfs `/tmp` = NixOS default (50 % RAM) — remove the explicit `tmp.tmpfsSize` (was 16G, broke a 16 GB host); fits 16 GB & 32 GB alike
- C39: builder advertises capacity over avahi — `_nixbuilder._tcp` TXT `cores` + `memgb` + `scperf` (single-core perf index, C44); static, set once at boot; ⊥ disk (fluctuates / misleading). Consumers read via SSH-query (resolve `nix-builder.local` natively, `ssh nproc`/`MemTotal` + the cached scperf) — portable; `avahi-browse` provided in the devShell on all platforms (used by the integration test, which browses on the Linux guest; macOS has no avahi-daemon for a local browse)
- C40: builder access serialized via an SSH-reachable lock — acquire **before** the main long op, **fail fast on contention** (⊥ wait), release in an **ensure block** so it clears on both success & failure; `just unlock` force-clears a stale lock left by a SIGKILL'd consumer (trap covers normal+fail, ⊥ kill-9). Locked = busy (e.g. Ryzen claimed for GPU). Lock covers smoke/boot/burn (QEMU/USB exclusivity); ⊥ `build` (nix-daemon serializes) & ⊥ external `nix.buildMachines` daemon builds — intentionally outside it
- C41: a job whose CPU/RAM/DISK exceeds the builder's advertised capacity ! error loudly — ⊥ silent under-provision; no pre-filtering, just announce + block
- C42: the capability advertiser is a persistent service (avahi-publish stays running to hold the mDNS record, like avahi-alias-nix-serve — ⊥ oneshot), runs unconditionally incl. inside QEMU guests (same ISO) — ⊥ suppression; correctness pinned by integration testing (smoke verifies the advertised TXT)
- C43: only `nix-builder.local` advertises/answers resources — find-builder prefers it, falls to other candidates (poe2.local) only when it is unreachable; a non-`nix-builder.local` builder → skip the resource check & size the guest from qemu-cmd defaults
- C44: `scperf` = single-core decompress throughput — stream a fixed, already-present compressed corpus (the kernel `.ko.xz` set, ~129 MB) to `/dev/null` with the in-closure `xz -dc -T1` (⊥ added pkg — `unsquashfs` is absent so ⊥ squashfs-tools; ⊥ baked fixture; ⊥ disk via `/dev/null`). Reuses real boot-decompression work; LZMA ≈ compiler-like (dict-match, pointer/branch/cache), no crypto/SIMD asymmetry; ⊥ gcc bloat. **Warm-then-time**: the `.ko.xz` sit inside the (32-threaded, USB-backed) squashfs, so an untimed read warms page-cache first, then only the decompress is timed — else USB/squashfs taints a single-core metric. ~5 s for the full ~706 MB corpus (or a fixed subset for ~1-2 s) after boot settles, `taskset`-pinned, measured once + cached at `/run/nix-builder-scperf`. Self-contained, ⊥ external table / hardcoded per-CPU numbers. Consumers scale timeouts (smoke/build/lefthook) by `baseline/scperf` — baseline = the Ryzen reference that consumer repos already build against (**3800X ≈ 141 MB/s single-core**, measured 2026-06-09); slower CPU → lower MB/s → longer timeout. Cross-machine ref (validates throughput-normalization across ISOs/corpora): i7-8650U ≈ 117 MB/s (0.83×) over a different 1325 MB corpus — comparable via MB/s despite the size difference

## §I INTERFACES

- I.boot: NixOS minimal ISO, UEFI + BIOS hybrid boot, serial console
- I.build: `just build` → `scripts/build/build.sh` → versioned ISO w/ SHA in filename
- I.version: ISO naming `nixos-nix-builder-<REL>-<DATE>-<TIME>-<SHA7>-x86_64-linux.iso`
- I.ssh: port 22, key-only, root + builder user authorized
- I.cache: nix-serve on :5000, signed (`nix-builder.local-1`), serves local nix store, LAN-accessible via `nix-builder.local:5000` & `nix-serve.local:5000`
- I.qemu-cache: fw_cfg `opt/nixos-nix-builder/nix_cache_url` → guest appends extra-substituter
- I.qemu: `just boot` → QEMU w/ SSH port-forwarding + nix-serve + virtual NVMe/SATA drives
- I.tty: `builder` user autologin on tty1
- I.storage: systemd oneshots mount NVMe → `/mnt/storage-nvme`, SATA → `/mnt/storage-sata`; `storage-link` symlinks `/mnt/storage` → fastest
- I.overlay: `nix-store-overlay` bind-mounts `/mnt/storage/nix-store-{upper,work}` over tmpfs `/nix/.rw-store/{store,work}` — before nix-daemon starts
- I.config: `just config` → interactive timezone/locale/keymap/fstype prompts
- I.devshell: `nix develop` — provides just, bats, shellcheck, lefthook
- I.remote-build: macOS `just build` → rsync to builder → `nix build` → ISO back
- I.smoke: `just smoke` → QEMU boot test w/ virtual NVMe + SATA, validates storage detection

## §V INVARIANTS

- V1: nix store overlay ! active before nix-daemon starts — builds land on disk, ⊥ tmpfs
- V2: USB disks ⊥ used as build storage — excluded from ∀ tier detection
- V3: storage tier preference NVMe > SATA, largest ext4 per tier, deterministic
- V4: nix-serve ! running on :5000 after boot — binary cache always available
- V5: QEMU guests auto-discover cache via fw_cfg — no hardcoded URLs in guest ISOs
- V6: SSH key-only — ⊥ password auth, ⊥ keyboard-interactive
- V7: builder user trusted by nix-daemon — remote `nix build` works w/o root
- V8: ISO filename embeds git SHA — dirty tree builds refused
- V9: ⊥ secrets in repo | ISO (keys in gitignored `secrets/`)
- V10: nix modules independent — no cross-module dependencies
- V11: shell fragments have no functions
- V12: ∀ shell script has 1-to-1 bats test file at reflective path
- V13: NixOS user uid/gid unique & numerically equal per user
- V14: storage-link failure → overlay skipped gracefully, nix stays on tmpfs
- V15: machine-id stable across boots — `5b23f4305970f426c3d1c00d0c2aa0e3`
- V16: builder user uid=1000/gid=1000
- V17: firewall allows :22 (SSH) + :5000 (nix-serve) + mDNS — ⊥ other inbound
- V18: QEMU uses virtio-net-pci — avoids e1000 TX hang bug
- V19: direct kernel boot in QEMU injects serial console — ISO ⊥ baked serial config
- V20: nix-serve starts after nix-store-overlay — serves disk-backed store, ⊥ tmpfs paths
- V21: locale/keymap/timezone read from `config/user/` at build time, defaults if absent
- V22: flake.lock committed & tracked — reproducible builds
- V23: NTP enabled (systemd-timesyncd)
- V24: nix-store-overlay ! verify `/nix/.rw-store/store` exists before bind-mount — ⊥ mount nonexistent path
- V25: storage mount chown ! run after user creation — ⊥ fail on missing builder user
- V26: overlay service has preStop cleanup — umount bind-mounts on nix-daemon restart
- V27: ⊥ `grep -P` anywhere — macOS BSD grep has no Perl regex support
- V28: `build.sh` on macOS ! error if no builder reachable — ⊥ silent success w/ no ISO
- V29: `create-drives.sh` ! cleanup losetup on any failure via trap
- V30: justfile recipes ! reference only existing scripts — ⊥ dangling calls
- V31: `.keep` files tracked despite parent dir gitignored — `git add -f`
- V32: nix-serve binds `0.0.0.0:5000` — LAN clients connect via mDNS, ⊥ localhost-only
- V33: dual mDNS: `nix-builder.local` & `nix-serve.local` both resolve to appliance
- V34: activation hashes script disabled — ⊥ ERR trap on locked-down user provisioning
- V35: QEMU shares host nix store via virtio-9p — guest reads host's store paths w/o rw overlay writes
- V36: nix store GC runs daily at 03:00 UTC, triggers when disk usage >80%, deletes roots older than 1 day — keeps 20% free for builds
- V37: guest mem = memgb (ceil MemTotal→GB), cpus = nproc — direct from builder specs, ⊥ reserve/subtract; Ryzen → ~2× the guest of T440p
- V38: tmpfs `/tmp` = 50 % RAM (NixOS default, no explicit override) — fits 16 GB & 32 GB
- V39: microcode auto-loaded for the running CPU (Intel on T440p | AMD on Ryzen) — both update paths in initrd, kernel picks the match
- V40: builder capacity (`cores`/`memgb`) advertised over avahi + readable via SSH-query — ⊥ disk, ⊥ hardcoded per-host constants
- V41: smoke/boot/burn serialized via SSH lock — acquire before long op (fail fast on contention), release in ensure block (success & failure); locked = unavailable. `build` & external daemon builds intentionally unlocked
- V42: a job exceeding builder CPU/RAM/DISK → loud error — ⊥ silent failure / under-provision
- V43: capability advertisement verified by smoke integration test — TXT `cores`/`memgb`/`scperf` present & correct in the booted guest
- V44: `scperf` advertised + SSH-readable; consumers scale timeouts vs the baseline (Ryzen 3800X ≈ 141 MB/s, measured) — ⊥ fixed timeouts on slow hardware

## §T TASKS

| id | st | task | cites |
|----|-----|------|-------|
| T1 | x | flake.nix: ISO builder + devShell w/ lefthook inputs | C1,C16 |
| T2 | x | modules/base.nix: headless, hostname `nix-builder.local`, locale config | C2,C21,I.tty |
| T3 | x | modules/hardware.nix: Ryzen 3800X, no GPU, latest kernel, tmpfs (superseded by T97 — any-host, both microcode, default tmpfs) | C3,C10 |
| T4 | x | modules/users.nix: builder (1000) + nixos users, autologin | V13,V16,I.tty |
| T5 | x | modules/ssh.nix: key-only auth, baked host key + authorized_keys | C8,V6,V9,I.ssh |
| T6 | x | modules/avahi.nix: mDNS publish `nix-builder.local` | C9 |
| T7 | x | modules/builder.nix: trusted-users, flakes, max-jobs auto | C18,C19,V7 |
| T8 | x | modules/nix-serve.nix: :5000 binary cache, firewall open | C6,V4,V17,V20,I.cache |
| T9 | x | modules/qemu.nix: QEMU package | C7 |
| T10 | x | modules/qemu-nix-cache.nix: fw_cfg substituter injection | C7a,V5,I.qemu-cache |
| T11 | x | modules/storage/{nvme,sata,link,overlay}.nix + fragments | C4,C5,V1-V3,V14,I.storage,I.overlay |
| T12 | x | modules/machine-id.nix: stable machine-id from md5 | C20,V15 |
| T13 | x | scripts/build/*: versioned ISO build, local+remote, SHA skip | C11,V8,I.build,I.version,I.remote-build |
| T14 | x | scripts/test-boot/*: QEMU cmd generator, create-drives, boot-local/remote, extract-kernel | C7,C24,V18,V19,I.qemu,I.smoke |
| T15 | x | scripts/config/*: interactive preferences | C21,V21,I.config |
| T16 | x | scripts/lib/find-builder.sh: builder discovery | C11 |
| T17 | x | justfile: build, boot, smoke, config recipes | C15 |
| T18 | x | fragments/nix-cache-qemu.sh: fw_cfg cache discovery | C7a,V5 |
| T19 | x | tests/*: bats 1-to-1 coverage for ∀ scripts + fragments | C14,V12 |
| T20 | x | CLAUDE.md + agent/set/*: project docs + conventions | - |
| T21 | x | lefthook.yml: ∀ nix-lefthook-* hooks as remotes | C14,C15 |
| T22 | x | README.md: architecture + dev architecture diagrams, nixos-poe2 mention | - |
| T23 | x | .envrc + linter configs (.markdownlint.jsonc, .yamllint.yml, .editorconfig) | C16 |
| T24 | x | CHANGELOG.md: initial release notes | - |
| T25 | x | flake.lock: generate & commit (requires `nix flake lock`) | C22,V22 |
| T26 | x | secrets setup: generate ssh_host_ed25519_key + authorized_keys | V9 |
| T27 | x | burn scripts: USB burn pipeline (interactive picker) (done in T50) | I.build |
| T28 | x | smoke test runner: expect-based orchestrator for QEMU validation (done in T36) | I.smoke |
| T29 | x | firewall.nix: explicit allow :22 + :5000, deny rest (superseded by T32) | V17 |
| T30 | x | nix-serve signing key: store path signing + cachix substituter | C6 |
| T31 | x | test: integration smoke -- QEMU boot validates storage overlay + nix-serve health (done in T36) | V1,V4 |
|     |   | **— gap analysis findings (2026-05-26) —** | |
| T32 | x | modules/firewall.nix: explicit enable, allow :22 + :5000 + mDNS, deny rest, log refused | V17,C25 |
| T33 | x | modules/ssh.nix: harden (MaxAuthTries=3, LoginGraceTime=30s, ⊥ TCP/agent forwarding) | C25,V6 |
| T34 | x | modules/boot.nix: kernel params (`nomodeset`, `consoleblank=1`), boot timeout 1s | C27,C31 |
| T35 | x | modules/default.nix: module aggregator — flake.nix imports single file | V10 |
| T36 | x | scripts/test-boot/test-boot.sh: smoke orchestrator (justfile `smoke` references it) | V30,I.smoke |
| T37 | x | scripts/test-boot/interpret-qemu-rc.sh: QEMU exit code handler | T36 |
| T38 | x | fix extract-kernel.sh: replace `grep -oP` w/ portable sed/awk | V27,C16 |
| T39 | x | fix build.sh: fail on macOS w/o builder instead of silent success | V28,C11 |
| T40 | x | fix create-drives.sh: trap-based losetup cleanup on any failure | V29 |
| T41 | x | fix nix-store-overlay.sh: check `/nix/.rw-store` exists, add preStop umount cleanup | V24,V26,V1 |
| T42 | x | fix storage-mount-target.sh: order after user creation \| use numeric uid for chown | V25 |
| T43 | x | qemu-cmd.sh: configurable memory/CPU via `QEMU_MEMORY`/`QEMU_SMP` env vars | C28 |
| T44 | x | users.nix: add kvm group, set `mutableUsers = false` | C29,C30,V13 |
| T45 | x | builder.nix: add `sandbox = true`, `build-dir = /mnt/storage/nix-builds` | C26,C32 |
| T46 | x | CHANGELOG.md: initial release notes (duplicate of T24) | - |
| T47 | x | .tdd-order-baseline + .coverage-allowlist + .shell-functions-allowlist | V12 |
| T48 | x | .nix-embedded-shell-allowlist: add `modules/nix-serve.nix` | V10,C13 |
| T49 | x | track `iso/.keep` + `secrets/.keep` via `git add -f` | V31 |
| T50 | x | scripts/burn/burn.sh: USB burn pipeline (justfile `reburn` references it) | V30,I.build |
| T51 | x | modules/avahi.nix: publish `nix-serve.local` as CNAME/alias alongside `nix-builder.local` | C6a,V33 |
| T52 | x | modules/activation-fixes.nix: disable `system.activationScripts.hashes` | C33,V34 |
|     |   | **-- tooling improvements (2026-05-26) --** | |
| T53 | x | lefthook.yml: add missing nix-lefthook-* remotes (flake-check, flake-eval, unit-coverage, etc.) + nix-lefthook base for lefthook 2.1.8 | C14 |
| T54 | x | migrate tests/ to tests/unit/ for bats 1-to-1 coverage, update all paths + skills | V12 |

|     |   | **-- streamlined pipeline (2026-05-26) --** | |
| T68 | x | justfile: wire smoke-check/mark into `smoke` recipe (skip if SHA already passed) | V30,I.smoke |
| T69 | x | justfile: add `resmoke` recipe -- force re-run smoke for current SHA | V30,I.smoke |
| T70 | x | .gitignore: add `.smoke-passed-*` + `.burn-done-*` marker files | V9 |
| T55 | x | scripts/burn/burn-check.sh: exit 0 if SHA already burned (marker `.burn-done-<sha>`) | V8 |
| T56 | x | scripts/burn/burn-mark.sh: write marker file after successful burn | T55 |
| T57 | x | scripts/burn/burn-auto.sh: auto-select HEAD ISO, skip ISO prompt (env `NIX_BUILDER_BURN_AUTO=1`) | T55,I.build |
| T58 | x | scripts/burn/burn.sh: honor `NIX_BUILDER_BURN_AUTO` + `NIX_BUILDER_BURN_CONFIRMED` env vars | T57,T59 |
| T59 | x | scripts/burn/burn-confirmed.sh: fully non-interactive burn (auto ISO + auto USB + skip BURN prompt) | T57,T58 |
| T60 | x | scripts/burn/burn-remote.sh: burn on builder over SSH (ISO stays on builder, USB attached there) | T58,I.remote-build |
| T61 | x | justfile: `burn` recipe -- smoke -> burn-auto with skip-if-done | T55,T57,V30 |
| T62 | x | justfile: `burn-confirmed` recipe -- full chain no prompts (smoke -> burn-confirmed + mark) | T59,V30 |
| T63 | x | tests/unit/burn/burn-check.bats: 1-to-1 coverage | T55,V12 |
| T64 | x | tests/unit/burn/burn-mark.bats: 1-to-1 coverage | T56,V12 |
| T65 | x | tests/unit/burn/burn-auto.bats: 1-to-1 coverage | T57,V12 |
| T66 | x | tests/unit/burn/burn-confirmed.bats: 1-to-1 coverage | T59,V12 |
| T67 | x | tests/unit/burn/burn-remote.bats: 1-to-1 coverage | T60,V12 |

|     |   | **-- integration coverage gaps (2026-05-26) --** | |
| T71 | x | live.exp: verify builder user trusted by nix-daemon (`nix show-config trusted-users`) | V7 |
| T72 | x | live.exp: verify firewall open for :22, :5000, :5353 and drop other ports | V17 |
| T73 | x | live.exp: verify nix-serve.local resolves via mDNS (avahi-resolve-host-name) | V33 |
| T74 | x | live.exp: verify nix `sandbox = true` via `nix show-config sandbox` | C26 |
| T75 | x | live.exp: verify builder user in kvm group (`id -Gn builder | grep kvm`) | C29 |
| T76 | x | live.exp: verify no runtime user changes allowed (declarative users only) | C30 |
| T77 | x | live.exp: verify nix max-jobs=auto and cores=0 | C19 |
| T78 | x | live.exp: verify nix-serve starts after nix-store-overlay (service ordering) | V20 |
| T79 | x | live.exp: verify overlay preStop cleanup handler wired | V26 |
| T80 | x | live.exp: verify no display-manager or X11 running (headless) | C2 |
| T81 | x | live.exp: verify /dev/kvm available for QEMU guests | C7 |
| T82 | x | live.exp: verify IdleAction=ignore and sleep target masked (no auto-shutdown) | C30 |
| T83 | x | live.exp: verify GRUB boot timeout = 1s | C31 |
| T84 | x | live.exp: verify AMD microcode loaded (superseded by T104 — vendor-agnostic Intel\|AMD) | C3 |
| T85 | x | live.exp: verify tmpfs /tmp sized 16G (superseded by T104 — 50% default) | C3 |
| T86 | x | live.exp: verify nix flakes and nix-command enabled | C18 |
| T87 | x | live.exp: verify NetworkManager running | C9 |
| T88 | x | live.exp: verify SSH host key is ed25519 only | C8 |
| T89 | x | live.exp: verify builder in wheel and networkmanager groups | C29 |
| T90 | x | live.exp: verify cachix substituter configured | C18 |
| T91 | x | smoke.exp: verify QEMU hostname override (nix-builder-qemu in serial output) | V33 |
| T92 | x | smoke.exp: add qemu-nix-cache to expected service list | C7a |
| T93 | x | smoke.exp: add storage-link to expected service list | V3 |
| T94 | x | smoke.exp: add nix-store-overlay to expected service list | V1 |

| T95 | | CI: dedicated x86_64-linux builder accessible from GitHub Actions | C11,C16 |
| T96 | x | modules/nix-store-gc.nix: periodic systemd timer + service, GC when disk >80%, delete-older-than 1d | V36 |
|     |   | **-- variable builder + resource sizing (2026-06-09) --** | |
| T97 | x | modules/hardware.nix: enable both intel+amd microcode (⊥ AMD-only); remove explicit `tmp.tmpfsSize` (inherit 50% default); verify T440p NIC `e1000e` + AHCI already in ISO (⊥ redundant initrd edit) | C36,C38,V38,V39 |
| T98 | | scripts/lib/builder-resources.sh: SSH-query `nproc` + `MemTotal` → `CORES`/`MEMGB` (ceil MemTotal→GB) — only for `nix-builder.local`; portable macOS+Linux | C39,C43,V40 |
| T99 | | modules/avahi-builder-capability.nix + fragment: PERSISTENT service (avahi-publish stays running, like avahi-alias-nix-serve — ⊥ oneshot) advertising `_nixbuilder._tcp` TXT (`cores`=nproc, `memgb`=ceil MemTotal→GB, `scperf`=table lookup) — static values, ⊥ disk | C39,C42,V40 |
| T100 | | integration test (smoke health-checks.tcl): ssh guest → `avahi-browse -rpt _nixbuilder._tcp`, assert TXT `cores`/`memgb`/`scperf` present & well-formed | C42,V43 |
| T101 | | sizing (direct, no formula): mem=memgb (ceil), cpus=nproc → export `QEMU_MEMORY`/`QEMU_SMP`; smoke-remote.sh + boot-remote.sh wire it before qemu-cmd — only when builder is `nix-builder.local`, else qemu-cmd defaults | C37,C43,V37 |
| T102 | | scripts/lib/builder-lock.sh: acquire (fail fast on contention) before the long op, release in an ensure/trap block (success & failure); smoke/boot/burn wrap their op (⊥ build; external daemon builds intentionally unlocked) | C40,V41 |
| T103 | | (deferred — ⊥ on this build) requirements check: job errors loudly when builder CPU/RAM/DISK < stated need | C41,V42 |
| T104 | x | health-checks.tcl: microcode check vendor-agnostic (Intel\|AMD); drop/relax tmpfs `=16G` assertion (now 50% default, T84/T85) | V38,V39 |
| T105 | | flake devShell: add `avahi` (avahi-browse) for Linux discovery/debug | C39 |
| T106 | | agent/set/concepts/hardware.md: variable builder (T440p \| Ryzen), single `nix-builder.local`, SSH-query sizing, SSH lock | C35 |
| T107 | | tests: bats coverage for builder-resources.sh, builder-lock.sh, avahi advertiser fragment | T98,T99,T102,V12 |
| T108 | | fragment: boot-time single-core decompress bench — warm-then-time (untimed cache-warm read, THEN timed `xz -dc -T1` of the sorted `.ko.xz` set → `/dev/null`, ⊥ I/O taint), after settle, `taskset` 1 core → `scperf` (throughput) cached at `/run/nix-builder-scperf`; advertiser + SSH-query read it (default no-scaling if absent); ⊥ added pkg, ⊥ fixture, ⊥ disk, ⊥ crypto, ⊥ gcc bloat | C44 |
| T109 | | consumers scale timeouts by `scperf` vs a baseline — smoke.exp, build, lefthook bracing timeouts | C44,V44 |
| T110 | | scripts/lib/builder-unlock.sh + justfile `unlock`: force-clear a stale `/run/nix-builder.lock` (SIGKILL escape hatch) | C40 |

## §B BUGS

- B10: GitHub Actions CI fails — needs dedicated x86_64-linux builder with nix + secrets access. Current CI only runs lefthook linters (skip-build: true). Full ISO build + smoke requires opensourced self-hosted runner or remote builder SSH tunnel from Actions.

| id | date | cause | fix |
|----|------|-------|-----|
| B1 | 2026-05-26 | justfile `smoke` references nonexistent `scripts/test-boot/test-boot.sh` | T36: create orchestrator |
| B2 | 2026-05-26 | justfile `reburn` references nonexistent `scripts/burn/burn.sh` | T50: create burn pipeline |
| B3 | 2026-05-26 | `extract-kernel.sh` uses `grep -oP` — breaks macOS (BSD grep ⊥ `-P`) | T38: replace w/ portable sed |
| B4 | 2026-05-26 | `build.sh` macOS silently succeeds when no builder reachable — exits 0 w/ no ISO | T39: fail explicitly |
| B5 | 2026-05-26 | `nix-store-overlay.sh` bind-mounts w/o checking `/nix/.rw-store` exists — mount fails | T41: add existence check |
| B6 | 2026-05-26 | `storage-mount-target.sh` chowns `builder:builder` — user may ⊥ exist at mount time | T42: numeric uid \| ordering fix |
| B7 | 2026-05-26 | `create-drives.sh` leaks losetup device if `mkfs.ext4` fails — no trap cleanup | T40: add trap |
| B8 | 2026-05-26 | `iso/.keep` + `secrets/.keep` gitignored — dirs missing after clone | T49: `git add -f` |
| B9 | 2026-05-26 | `.nix-embedded-shell-allowlist` missing `modules/nix-serve.nix` (inline ExecStart) | T48: add to allowlist |
| B11 | 2026-07-01 | `iso_store_dir.bats` test runs unsandboxed — fails on hosts where `/mnt/storage` exists but is not writable | fixed: sandbox test with temp dir |
| B12 | 2026-07-01 | `flake.nix` overrides non-existent `nix-lefthook-bats-failures-only` input on `nix-lefthook-bats-changed` — upstream renamed to `-src` | fixed: remove stale follows override |
| B13 | 2026-07-01 | 5 bats test files use `run !` syntax without `bats_require_minimum_version 1.5.0` — emits BW02 deprecation warnings | fixed: add version declaration |
| B14 | 2026-07-03 | `nixos` user/group lacked explicit uid/gid — V13 violation, auto-assigned values risked collision | fixed: assign uid/gid 999 |
| B15 | 2026-07-03 | nix-serve + avahi-alias services ran w/o systemd hardening (⊥ NoNewPrivileges, ⊥ ProtectHome) | fixed: add hardening directives |
| B16 | 2026-07-03 | `qemu.nix` had dead `virtualisation.libvirtd.enable = false` (already default) | fixed: remove |
| B17 | 2026-07-13 | `.editorconfig` set `*.sh` indent_size to 2 but shell files kept 4-space case body indent — shfmt CI check failed | fixed: reformat with `shfmt -w` |
