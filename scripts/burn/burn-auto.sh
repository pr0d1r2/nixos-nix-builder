#!/usr/bin/env bash
# Auto-select HEAD ISO and burn (still prompts for USB + confirmation).
# Tries remote builder first (ISO stays on builder), falls back to local.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export NIX_BUILDER_BURN_AUTO=1

bash "$REPO_ROOT/scripts/burn/burn-remote.sh" && exit 0
rc=$?
if [ "$rc" -eq 2 ]; then
    exec bash "$REPO_ROOT/scripts/burn/burn.sh"
fi
exit "$rc"
