#!/usr/bin/env bash
# Burn ISO on remote builder over SSH.
# ISO stays on builder, USB attached to builder.
# Exit codes: 0=success, 1=remote failed, 2=not attempted (no builder).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "${NIX_BUILDER_BURN_LOCAL:-}" = "1" ]; then
    echo "burn-remote: local-only mode, skipping." >&2
    exit 2
fi

BUILDER="$(bash "$REPO_ROOT/scripts/lib/find-builder.sh" 2>/dev/null)" || {
    echo "burn-remote: no reachable builder, falling back to local." >&2
    exit 2
}

REMOTE_DIR="$(ssh "$BUILDER" \
    'if [ -d /mnt/storage ]; then echo /mnt/storage/nix-builder-burn; else echo /tmp/nix-builder-burn; fi')"
# shellcheck disable=SC2029
ssh "$BUILDER" "mkdir -p '$REMOTE_DIR/scripts/burn'"
rsync -az --delete "$REPO_ROOT/scripts/burn/" "$BUILDER:$REMOTE_DIR/scripts/burn/"

ISO_DIR="$(ssh "$BUILDER" sh <"$REPO_ROOT/scripts/build/iso_store_dir.sh")"

HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD 2>/dev/null || true)"

REMOTE_ENV=""
[ "${NIX_BUILDER_BURN_AUTO:-}" = "1" ] && REMOTE_ENV="NIX_BUILDER_BURN_AUTO=1 "
[ "${NIX_BUILDER_BURN_CONFIRMED:-}" = "1" ] && REMOTE_ENV="${REMOTE_ENV}NIX_BUILDER_BURN_CONFIRMED=1 "
[ -n "$HEAD_SHA" ] && REMOTE_ENV="${REMOTE_ENV}NIX_BUILDER_HEAD_SHA=$HEAD_SHA "

# shellcheck disable=SC2029
ssh -t "$BUILDER" "cd $REMOTE_DIR && ${REMOTE_ENV}bash scripts/burn/burn.sh '$ISO_DIR'"
