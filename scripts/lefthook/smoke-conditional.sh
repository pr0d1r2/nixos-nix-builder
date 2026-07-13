#!/usr/bin/env bash
# Conditional smoke test for pre-push.
#
# Runs QEMU smoke test only when:
#   1. nix-builder.local is reachable (remote QEMU host)
#   2. Smoke not already passed for current SHA
#
# Skips silently (exit 0) when either condition fails.
# Best-effort integration gate, not a hard blocker.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

HOST="${NIX_BUILDER_HOST:-nix-builder.local}"

if ! bash "$REPO_ROOT/scripts/lib/ping-wait.sh" "$HOST" 2>/dev/null; then
  echo "smoke-conditional: builder unreachable, skipping"
  exit 0
fi

if bash "$REPO_ROOT/scripts/test-boot/smoke-check.sh" 2>/dev/null; then
  echo "smoke-conditional: already passed for HEAD, skipping"
  exit 0
fi

echo "smoke-conditional: builder reachable + smoke not passed, running"
bash "$REPO_ROOT/scripts/test-boot/test-boot.sh"
bash "$REPO_ROOT/scripts/test-boot/smoke-mark.sh"
