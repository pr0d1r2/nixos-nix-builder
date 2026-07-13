#!/usr/bin/env bash
set -euo pipefail

ip="$(hostname -I | awk '{print $1}')"
if [ -z "$ip" ]; then
  echo "avahi-alias: no IP address found" >&2
  exit 1
fi

hn="$(hostname)"
if [ "$hn" = "nix-builder" ]; then
  alias="nix-serve.local"
else
  alias="nix-serve-${hn#nix-builder-}.local"
fi

exec avahi-publish -a -R "$alias" "$ip"
