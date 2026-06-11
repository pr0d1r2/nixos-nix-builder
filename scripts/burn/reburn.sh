#!/usr/bin/env bash
# Interactive ISO burn, remote-first.
# Tries builder over SSH. Falls back to local on no builder (exit 2).
# Propagates remote failures (exit 1).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

bash "$REPO_ROOT/scripts/burn/burn-remote.sh" && exit 0
rc=$?
if [ "$rc" -eq 2 ]; then
  exec bash "$REPO_ROOT/scripts/burn/burn.sh"
fi
exit "$rc"
