#!/usr/bin/env bash
set -uo pipefail

umount /mnt/nix-host-store 2>/dev/null || true
