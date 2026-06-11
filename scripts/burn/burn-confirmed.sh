#!/usr/bin/env bash
# Fully non-interactive burn: auto ISO + auto USB + skip BURN prompt.
# Tries remote builder first, falls back to local.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export NIX_BUILDER_BURN_AUTO=1
export NIX_BUILDER_BURN_CONFIRMED=1

bash "$REPO_ROOT/scripts/burn/burn-remote.sh" && exit 0
rc=$?
if [ "$rc" -eq 2 ]; then
  exec bash "$REPO_ROOT/scripts/burn/burn.sh"
fi
exit "$rc"
