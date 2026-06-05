#!/usr/bin/env bash
# Mark burn as done for current git SHA.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHORT_SHA="$(git -C "$REPO_ROOT" rev-parse --short=7 HEAD)"
MARKER="$REPO_ROOT/.burn-done-$SHORT_SHA"

date -Iseconds >"$MARKER"
echo "burn: marked $SHORT_SHA as done" >&2
