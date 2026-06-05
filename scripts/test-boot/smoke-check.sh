#!/usr/bin/env bash
# Check if smoke test already passed for current git SHA.
# Exit 0 if already passed, 1 if not.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHORT_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD)"
MARKER="$REPO_ROOT/.smoke-passed-$SHORT_SHA"

if [ -f "$MARKER" ]; then
    echo "smoke: already passed for $SHORT_SHA ($(cat "$MARKER"))" >&2
    exit 0
fi

exit 1
