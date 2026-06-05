#!/usr/bin/env bash
# Exit 0 if ISO already exists for current git SHA, 1 if not.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHORT_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD)"

# shellcheck disable=SC2012
ISO="$(ls -t "$REPO_ROOT/iso/"*"${SHORT_SHA}"*.iso 2>/dev/null | head -n1 || true)"
if [ -n "$ISO" ]; then
    echo "build: $(basename "$ISO") exists for $SHORT_SHA" >&2
    exit 0
fi

if [ "$(uname -s)" = "Darwin" ]; then
    builder="$(bash "$REPO_ROOT/scripts/lib/find-builder.sh" 2>/dev/null || true)"
    if [ -n "$builder" ]; then
        store_dir="$(ssh "$builder" sh <"$REPO_ROOT/scripts/build/iso_store_dir.sh")"
        # shellcheck disable=SC2029
        remote_iso="$(ssh "$builder" "ls -t '$store_dir/'*'${SHORT_SHA}'*.iso 2>/dev/null | head -n1" || true)"
        if [ -n "$remote_iso" ]; then
            echo "build: $(basename "$remote_iso") exists on $builder for $SHORT_SHA" >&2
            exit 0
        fi
    fi
fi

exit 1
