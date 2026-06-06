#!/usr/bin/env bash
set -euo pipefail

echo "nixos-nix-builder dev shell"

export LEFTHOOK_TDD_PATHS=":(glob)scripts/**/*.sh :(glob)fragments/*.sh :(glob)nix/dev/*.sh"
export LEFTHOOK_TDD_EXCLUDE="scripts/lefthook/*"
export LEFTHOOK_TDD_SPEC_DIR="tests/unit"
export LEFTHOOK_SKILL_REGISTERED_FILE="CLAUDE.md"
export LEFTHOOK_SKILL_REGISTERED_PREFIX="@agent/set/"
export LEFTHOOK_SKILL_REGISTERED_STRIP="agent/set/"

LEFTHOOK_HASH=$(md5 -q lefthook.yml 2>/dev/null || md5sum lefthook.yml | cut -d' ' -f1)
LEFTHOOK_HASH_FILE=".git/.lefthook-hash"
if [ ! -f "$LEFTHOOK_HASH_FILE" ] || [ "$(cat "$LEFTHOOK_HASH_FILE")" != "$LEFTHOOK_HASH" ]; then
    lefthook install
    echo "$LEFTHOOK_HASH" >"$LEFTHOOK_HASH_FILE"
fi
