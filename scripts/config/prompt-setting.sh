#!/usr/bin/env bash
# Prompt for a config setting. Saves to file.
# Usage: bash prompt-setting.sh <file> <label> <default>

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
file="$1"
label="$2"
default="${3:-}"

current="$(bash "$SCRIPT_DIR/read-existing.sh" "$file")"

if [ -n "$current" ]; then
    printf '%s [%s]: ' "$label" "$current" >&2
elif [ -n "$default" ]; then
    printf '%s (default: %s): ' "$label" "$default" >&2
else
    printf '%s: ' "$label" >&2
fi

read -r input

if [ -z "$input" ]; then
    if [ -n "$current" ]; then
        input="$current"
    elif [ -n "$default" ]; then
        input="$default"
    else
        echo "config: $label is required" >&2
        exit 1
    fi
fi

printf '%s' "$input" >"$file"
echo "config: $label = $input" >&2
