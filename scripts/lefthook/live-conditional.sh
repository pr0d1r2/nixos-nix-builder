#!/usr/bin/env bash
# Conditional live integration test for pre-push.
#
# Runs live.exp against nix-builder.local only when the node
# is reachable. Skips silently (exit 0) when node is down.
# Best-effort integration gate, not a hard blocker.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

HOST="${NIX_BUILDER_HOST:-nix-builder.local}"

if ! bash "$REPO_ROOT/scripts/lib/ping-wait.sh" "$HOST" 2>/dev/null; then
  echo "live-conditional: node unreachable, skipping"
  exit 0
fi

echo "live-conditional: node reachable, running live integration"
expect "$REPO_ROOT/tests/integration/live.exp" "$HOST" 22
