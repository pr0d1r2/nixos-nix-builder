#!/usr/bin/env bash
# Run live integration tests against a booted nix-builder node.
# Usage: live.sh [host] [port]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

host="${1:-nix-builder.local}"
port="${2:-22}"

expect "$REPO_ROOT/tests/integration/live.exp" "$host" "$port"
