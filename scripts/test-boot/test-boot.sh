#!/usr/bin/env bash
# QEMU smoke test orchestrator.
# Usage: bash scripts/test-boot/test-boot.sh [iso-path]
#
# Runs expect which spawns the appropriate smoke script:
#   macOS        -> smoke-remote.sh (QEMU on nix-builder.local via SSH)
#   Linux x86_64 -> smoke-local.sh  (QEMU locally with KVM)
#
# The expect script handles OS detection and spawns the right script.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

expect "$REPO_ROOT/tests/integration/smoke.exp" "$@"
