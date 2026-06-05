#!/usr/bin/env bash
# Interactive configuration for user preferences.
# Prompts for each setting; press Enter to keep existing value.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
CONFIG_DIR="$REPO_ROOT/config/user"

mkdir -p "$CONFIG_DIR"

echo "=== nixos-nix-builder configuration ===" >&2
echo >&2

bash "$SCRIPT_DIR/prompt-setting.sh" "$CONFIG_DIR/timezone" "Timezone" "Europe/Warsaw"
bash "$SCRIPT_DIR/prompt-setting.sh" "$CONFIG_DIR/locale" "Locale" "en_US.UTF-8"
bash "$SCRIPT_DIR/prompt-setting.sh" "$CONFIG_DIR/keymap" "Console keymap" "us"
bash "$SCRIPT_DIR/prompt-setting.sh" "$CONFIG_DIR/fstype" "Storage filesystem" "ext4"

echo >&2
echo "config: all preferences saved" >&2
