#!/usr/bin/env bash
# Discover an x86_64-linux builder on the local network.
# Tries nix-builder.local first, then poe2.local.
# Prints "root@<host>" on success, exits 1 if none found.
#
# Usage: builder="$(bash scripts/lib/find-builder.sh)"

set -euo pipefail

CANDIDATES=(
  "root@nix-builder.local"
  "root@poe2.local"
)

hn="$(hostname -s 2>/dev/null || uname -n)"
RETRIES="${FIND_BUILDER_RETRIES:-3}"

for attempt in $(seq 1 "$RETRIES"); do
  for builder in "${CANDIDATES[@]}"; do
    host="${builder#*@}"
    host_short="${host%%.*}"
    case "$hn" in
    "$host_short" | "$host_short".*) continue ;;
    esac
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$builder" true 2>/dev/null; then
      echo "$builder"
      exit 0
    fi
  done
  if [ "$attempt" -lt "$RETRIES" ]; then
    sleep 5
  fi
done

echo "find-builder: no reachable builder (tried: ${CANDIDATES[*]})" >&2
exit 1
