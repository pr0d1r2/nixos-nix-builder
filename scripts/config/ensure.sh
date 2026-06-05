#!/usr/bin/env bash
# Ensure all preferences and secrets are ready before build.
# Usage: bash ensure.sh

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

if ! bash "$SCRIPT_DIR/check.sh" 2>/dev/null; then
    echo "config: some preferences missing, launching configuration..." >&2
    bash "$SCRIPT_DIR/configure.sh"
fi

bash "$SCRIPT_DIR/setup-secrets.sh"
