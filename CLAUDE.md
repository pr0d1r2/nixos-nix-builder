# nixos-nix-builder

Bootable NixOS USB -- purpose-built nix builder appliance. No desktop, headless.

## Quick reference

- **Build:** `just build` or `bash scripts/build/build.sh`
- **Burn:** `just reburn` or `bash scripts/burn/burn.sh`
- **Builder:** `nix-builder.local` (remote x86_64-linux)

## Project structure

```
flake.nix                    # ISO builder + devShell
modules/
  base.nix                   # Hostname, locale, headless
  hardware.nix               # Ryzen 3700X (no GPU)
  ssh.nix                    # SSH server + baked keys
  avahi.nix                  # mDNS discovery
  builder.nix                # Nix config, trusted-users
  nix-serve.nix              # Binary cache on :5000
  qemu.nix                   # QEMU packages
  qemu-nix-cache.nix         # fw_cfg cache for guests
  users.nix                  # builder + nixos users
  power.nix                  # Disable sleep/suspend/hibernate
  machine-id.nix             # Stable machine-id
  storage/
    nvme.nix                 # Mount largest NVMe ext4
    sata.nix                 # Mount largest SATA ext4
    link.nix                 # Symlink /mnt/storage -> fastest
    overlay.nix              # Nix store: tmpfs -> disk
fragments/                   # Shell script bodies for systemd units
scripts/
  build/                     # SHA-versioned ISO build
  test-boot/                 # QEMU smoke testing
  config/                    # Interactive preferences
  lib/                       # Shared utilities
```

## Conventions

@agent/set/concepts/hardware.md
@agent/set/concepts/user.md
@agent/set/skills/architecture.md
@agent/set/skills/architecture/development.md
@agent/set/skills/architecture/remote/first.md
@agent/set/skills/direnv.md
@agent/set/skills/dotfile.md
@agent/set/skills/dx.md
@agent/set/skills/git.md
@agent/set/skills/gnu.md
@agent/set/skills/gnu/awk.md
@agent/set/skills/gnu/coreutils.md
@agent/set/skills/gnu/find.md
@agent/set/skills/gnu/grep.md
@agent/set/skills/gnu/sed.md
@agent/set/skills/implementation.md
@agent/set/skills/just.md
@agent/set/skills/just/modularity.md
@agent/set/skills/just/modules.md
@agent/set/skills/justfile.md
@agent/set/skills/language.md
@agent/set/skills/language/active.md
@agent/set/skills/language/anodyne.md
@agent/set/skills/language/concise.md
@agent/set/skills/language/imperative.md
@agent/set/skills/language/narrow.md
@agent/set/skills/language/operator.md
@agent/set/skills/lefthook.md
@agent/set/skills/linter.md
@agent/set/skills/lefthook/agentic.md
@agent/set/skills/lefthook/conditional.md
@agent/set/skills/lefthook/glob.md
@agent/set/skills/lefthook/modularity.md
@agent/set/skills/lefthook/nix.md
@agent/set/skills/lefthook/sh.md
@agent/set/skills/lefthook/tdd.md
@agent/set/skills/lefthook/timeout.md
@agent/set/skills/nix/flake.md
@agent/set/skills/nix/modularity.md
@agent/set/skills/nixos/security/wrappers.md
@agent/set/skills/nixos/users.md
@agent/set/skills/nixos/users/modularity.md
@agent/set/skills/parallel.md
@agent/set/skills/qemu/cleanup.md
@agent/set/skills/qemu/direct-boot.md
@agent/set/skills/qemu/mdns.md
@agent/set/skills/performance.md
@agent/set/skills/product.md
@agent/set/skills/product/plan.md
@agent/set/skills/portability.md
@agent/set/skills/rtk.md
@agent/set/skills/semble.md
@agent/set/skills/security.md
@agent/set/skills/security/credentials.md
@agent/set/skills/security/personal.md
@agent/set/skills/sh.md
@agent/set/skills/skill.md
@agent/set/skills/streamline.md
@agent/set/skills/sh/modularity.md
@agent/set/skills/sh/noexec.md
@agent/set/skills/tdd.md
@agent/set/skills/test/coverage.md
@agent/set/skills/test/unit.md
@agent/set/skills/test/unit/sh.md
@agent/set/skills/test/integration/remote.md
@agent/set/skills/test/integration/shared.md
@agent/set/skills/ux.md
