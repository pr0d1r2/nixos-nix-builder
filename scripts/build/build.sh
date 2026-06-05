#!/usr/bin/env bash
# ISO build orchestrator.
# Linux x86_64 -> local nix build
# macOS        -> remote build on nix-builder.local

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "build: FAILED at scripts/build/build.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

NIXOS_REL="25.11"
TARGET_ARCH="x86_64"
TARGET_OS="linux"

if ! git diff --quiet --exit-code || ! git diff --cached --quiet --exit-code; then
    echo "build: refusing to build from a dirty tree. Commit your changes first." >&2
    exit 1
fi
GITSHA="$(git rev-parse HEAD)"
SHORT_SHA="${GITSHA:0:7}"

mkdir -p "$REPO_ROOT/iso"

# shellcheck disable=SC2012
EXISTING="$(ls -t "$REPO_ROOT/iso/"*"${SHORT_SHA}"*.iso 2>/dev/null | head -n1 || true)"
if [ -n "$EXISTING" ]; then
    echo "build: $(basename "$EXISTING") already exists locally -- skipping build."
    exit 0
fi

if [ "$(uname -s)" = "Darwin" ]; then
    builder="$(bash "$REPO_ROOT/scripts/lib/find-builder.sh" 2>/dev/null || true)"
    if [ -z "$builder" ]; then
        echo "build: no builder reachable -- cannot build on macOS without an x86_64-linux builder." >&2
        exit 1
    fi
    store_dir="$(ssh "$builder" sh <"$REPO_ROOT/scripts/build/iso_store_dir.sh")"
    # shellcheck disable=SC2029
    remote_iso="$(ssh "$builder" "ls -t '$store_dir/'*'${SHORT_SHA}'*.iso 2>/dev/null | head -n1" || true)"
    if [ -n "$remote_iso" ]; then
        echo "build: $(basename "$remote_iso") already exists on $builder -- skipping build."
        exit 0
    fi
fi

TS="$(date -u +%Y%m%d-%H%M)"
DATE="${TS%-*}"
TIME="${TS#*-}"

FILENAME="$(bash "$REPO_ROOT/scripts/build/version.sh" \
    "$NIXOS_REL" "$DATE" "$TIME" "$GITSHA" "$TARGET_ARCH" "$TARGET_OS")"
TARGET="$REPO_ROOT/iso/$FILENAME"

HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"

case "$HOST_OS-$HOST_ARCH" in
    Linux-x86_64)
        nix build \
            --extra-experimental-features 'nix-command flakes' \
            '.#nixosConfigurations.nixos-nix-builder.config.system.build.isoImage' \
            --out-link "$REPO_ROOT/iso/.result"
        ;;
    Darwin-*)
        bash "$REPO_ROOT/scripts/build/build-remote.sh" \
            "$REPO_ROOT" "$NIXOS_REL" "$DATE" "$TIME" "$GITSHA" "$FILENAME"
        ;;
    *)
        echo "build: unsupported host $HOST_OS-$HOST_ARCH." >&2
        exit 1
        ;;
esac

SKIP_DOWNLOAD=0
[ "${NIX_BUILDER_BURN_BUILD:-0}" = "1" ] && SKIP_DOWNLOAD=1
if [ "$SKIP_DOWNLOAD" = "1" ] && [ "$HOST_OS" = "Darwin" ]; then
    echo "build: ISO kept on builder (not downloaded)"
else
    RESULT_LINK="$REPO_ROOT/iso/.result"
    if [ ! -e "$RESULT_LINK" ]; then
        echo "build: nix build did not produce $RESULT_LINK" >&2
        exit 1
    fi
    ISO_PATH="$(find -L "$RESULT_LINK/iso" -maxdepth 1 -name '*.iso' -print -quit)"
    if [ -z "$ISO_PATH" ]; then
        echo "build: no .iso found inside $RESULT_LINK/iso" >&2
        exit 1
    fi
    cp -L "$ISO_PATH" "$TARGET"
    rm -rf "$RESULT_LINK"

    echo
    echo "build: wrote $TARGET"
fi
