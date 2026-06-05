#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

builder="$(bash "$REPO_ROOT/scripts/lib/find-builder.sh")"
echo "shutdown: sending shutdown to $builder"
ssh -o ConnectTimeout=5 "$builder" "shutdown now" 2>/dev/null || true
echo "shutdown: command sent"
