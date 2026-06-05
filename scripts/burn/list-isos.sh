#!/usr/bin/env bash
# List *.iso files in a directory, newest-first by mtime.

set -euo pipefail

DIR="${1:-iso}"

if [ ! -d "$DIR" ]; then
    echo "list-isos: No ISOs found in '$DIR' (directory does not exist). Run 'just build' first." >&2
    exit 1
fi

# shellcheck disable=SC2012
mapfile -t isos < <(cd "$DIR" && ls -t -- *.iso 2>/dev/null || true)

if [ ${#isos[@]} -eq 0 ]; then
    echo "list-isos: No ISOs found in '$DIR'. Run 'just build' first." >&2
    exit 1
fi

printf '%s\n' "${isos[@]}"
