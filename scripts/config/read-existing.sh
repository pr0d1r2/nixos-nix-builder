#!/usr/bin/env bash
# Read existing config value from file. Prints value or empty string.
# Usage: bash read-existing.sh <file>

set -euo pipefail

file="$1"

if [ -f "$file" ]; then
    cat "$file"
fi
