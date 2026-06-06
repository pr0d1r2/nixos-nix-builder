#!/usr/bin/env bash
# Garbage-collect the nix store when disk usage exceeds threshold.
#
# Runs as a periodic systemd timer. Checks the filesystem backing
# /nix/store and triggers GC when usage exceeds 80% (keeping 20%
# free for builds and PoE2 patches).
#
# Two-phase cleanup:
#   1. Delete GC roots older than 1 day
#   2. Collect garbage (unreachable store paths)

set -euo pipefail

THRESHOLD="${NIX_GC_THRESHOLD:-80}"

mount_point="$(df --output=target /nix/store 2>/dev/null | tail -1)"
usage_pct="$(df --output=pcent /nix/store 2>/dev/null | tail -1 | tr -dc '0-9')"

if [ -z "$usage_pct" ]; then
    echo "nix-store-gc: could not determine /nix/store usage -- skipping" >&2
    exit 0
fi

echo "nix-store-gc: /nix/store on $mount_point at ${usage_pct}% (threshold ${THRESHOLD}%)"

if [ "$usage_pct" -le "$THRESHOLD" ]; then
    echo "nix-store-gc: below threshold -- no action needed"
    exit 0
fi

echo "nix-store-gc: usage ${usage_pct}% exceeds ${THRESHOLD}% -- collecting garbage"

nix-collect-garbage --delete-older-than 1d 2>&1

usage_after="$(df --output=pcent /nix/store 2>/dev/null | tail -1 | tr -dc '0-9')"
avail_gb="$(df --output=avail -BG /nix/store 2>/dev/null | tail -1 | tr -dc '0-9')"

echo "nix-store-gc: done -- ${usage_after}% used, ${avail_gb}G available"
