#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: ping-wait.sh <host>}"

TIMEOUTS=(1 2 5)

for timeout in "${TIMEOUTS[@]}"; do
  if ping -c 1 -W "$timeout" "$HOST" >/dev/null 2>&1; then
    exit 0
  fi
done

echo "ping-wait: $HOST not reachable (ping failed after 3 retries)" >&2
exit 1
