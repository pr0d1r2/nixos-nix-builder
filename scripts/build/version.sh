#!/usr/bin/env bash
# ISO filename generator.
# Naming: nixos-nix-builder-<NIXOS_REL>-<YYYYMMDD>-<HHMM>-<GITSHA[:7]>-x86_64-linux.iso

set -euo pipefail

if [ $# -ne 6 ]; then
    cat <<'USAGE' >&2
Usage: version.sh NIXOS_REL YYYYMMDD HHMM GITSHA ARCH OS

Prints the canonical ISO filename. GITSHA is truncated to 7 chars.
USAGE
    exit 2
fi

nixos_rel="$1"
date="$2"
time="$3"
gitsha="$4"
arch="$5"
os="$6"

short_sha="${gitsha:0:7}"

printf 'nixos-nix-builder-%s-%s-%s-%s-%s-%s.iso\n' \
    "$nixos_rel" "$date" "$time" "$short_sha" "$arch" "$os"
