#!/usr/bin/env sh
# Resolve ISO store directory on the builder.
# POSIX sh -- can be streamed over `ssh sh`.
#
# Preference: /mnt/storage-fast > /mnt/storage > /tmp

set -eu

if [ -d /mnt/storage-fast ]; then
    store=/mnt/storage-fast/nix-builder-iso
elif [ -d /mnt/storage ]; then
    store=/mnt/storage/nix-builder-iso
else
    store=/tmp/nix-builder-iso # nolocalpath
fi

mkdir -p "$store"
printf '%s\n' "$store"
