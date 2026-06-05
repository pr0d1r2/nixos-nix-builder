#!/usr/bin/env bash
# Exit 0 if all user preferences are configured, 1 if any missing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="$REPO_ROOT/config/user"

missing=0

for setting in timezone locale keymap fstype; do
    if [ ! -f "$CONFIG_DIR/$setting" ]; then
        echo "config: missing $CONFIG_DIR/$setting" >&2
        missing=1
    fi
done

exit "$missing"
