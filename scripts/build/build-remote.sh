#!/usr/bin/env bash
# Remote nix build on nix-builder.local.
# Rsyncs tree to builder, runs nix build, stages ISO.

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'rc=$?; echo "build-remote: FAILED at scripts/build/build-remote.sh:${LINENO} (exit $rc): ${BASH_COMMAND}" >&2' ERR

if [ $# -ne 6 ]; then
    echo "Usage: build-remote.sh <repo_root> <nixos_rel> <date> <time> <gitsha> <filename>" >&2
    exit 2
fi

REPO_ROOT="$1"
NIXOS_REL="$2"
DATE="$3"
TIME="$4"
GITSHA="$5"
FILENAME="$6"

builder="$(bash "$(dirname "${BASH_SOURCE[0]}")/../lib/find-builder.sh")"

remote_parent="$(ssh "$builder" \
    'if [ -d /mnt/storage ]; then echo /mnt/storage; else echo /tmp; fi')"
remote_dir="$remote_parent/nix-builder-${NIXOS_REL}-${DATE}-${TIME}-${GITSHA:0:7}"

echo "build: remote nix build on $builder at $remote_dir"

# shellcheck disable=SC2064
trap "ssh '$builder' 'rm -rf -- \"$remote_dir\"' || true" EXIT

# shellcheck disable=SC2029
ssh "$builder" "mkdir -p '$remote_dir'"
rsync -rlptDz --delete --no-owner --no-group \
    --exclude '/.git/' \
    --exclude '/iso/' \
    --exclude '/result' \
    --exclude '/.result' \
    "$REPO_ROOT/" "$builder:$remote_dir/"

# shellcheck disable=SC2029
ssh "$builder" "cd '$remote_dir' && git init -q && git add -f . 2>/dev/null && git -c user.name=build -c user.email=build commit -q -m 'build ${GITSHA:0:7}' 2>/dev/null"

# shellcheck disable=SC2029
ssh "$builder" "cd '$remote_dir' && nix build \
    --extra-experimental-features 'nix-command flakes' \
    --print-build-logs \
    '.#nixosConfigurations.nixos-nix-builder.config.system.build.isoImage' \
    --out-link '$remote_dir/.result'"

# Remote-first: the ISO stays on the builder. We never rsync it back to
# the Mac -- every consumer (smoke, burn, boot-remote) reads it from the
# builder store. Downloading 1.7G per build only filled the Mac disk.
echo "build: ISO kept on builder -- not downloaded to this host"

store_dir="$(ssh "$builder" sh <"$REPO_ROOT/scripts/build/iso_store_dir.sh")"
# shellcheck disable=SC2029
ssh "$builder" "rm -f '$store_dir'/nixos-nix-builder-*.iso"
# shellcheck disable=SC2029
ssh "$builder" "cp -L '$remote_dir/.result/iso/'*.iso '$store_dir/$FILENAME'"
echo "build: staged $FILENAME in $builder:$store_dir"
