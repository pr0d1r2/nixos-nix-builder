#!/usr/bin/env bash
# Mark smoke test as passed for current git SHA.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHORT_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD)"
MARKER="$REPO_ROOT/.smoke-passed-$SHORT_SHA"

date -Iseconds >"$MARKER"
echo "smoke: marked $SHORT_SHA as passed" >&2
