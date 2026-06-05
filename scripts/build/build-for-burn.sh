#!/usr/bin/env bash
# Build ISO for burn workflow -- keeps ISO on builder, skips download.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export NIX_BUILDER_BURN_BUILD=1
bash "$REPO_ROOT/scripts/build/build-check.sh" || bash "$REPO_ROOT/scripts/build/build.sh"
