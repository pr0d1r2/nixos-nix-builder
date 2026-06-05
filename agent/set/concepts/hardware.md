Development and testing hardware for the nixos-nix-builder project.

## Development host

MacBook Air M4, 16 GB RAM (aarch64-darwin). Runs the dev shell, editor, and Claude Code. Builds are delegated to the builder via `just build`.

## Builder / Target

Ryzen 3700X (8 cores / 16 threads), 32 GB RAM (x86_64-linux). This is both the build host and the target hardware — the builder builds its own ISO. Internal NVMe or SATA disk with ext4 partition for nix store overlay.

## USB pendrive

Kingston DataTraveler Kyson 128 GB (USB 3.2 Gen 1). Stateless — no persistent data on pendrive, all nix store data on host's internal disk via overlay.

## Network

All nodes connected via 1 Gbit/s Ethernet.
