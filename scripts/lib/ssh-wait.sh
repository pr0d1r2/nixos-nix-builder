#!/usr/bin/env bash
set -euo pipefail

HOST="${1:?Usage: ssh-wait.sh <host> [port] [user]}"
PORT="${2:-22}"
USER="${3:-builder}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/ping-wait.sh" "$HOST"

TIMEOUTS=(1 2 5)

for timeout in "${TIMEOUTS[@]}"; do
    if ssh -o BatchMode=yes -o ConnectTimeout="$timeout" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        -p "$PORT" "${USER}@${HOST}" true 2>/dev/null; then
        exit 0
    fi
done

echo "ssh-wait: $HOST:$PORT SSH unreachable after 3 retries (1s, 2s, 5s)" >&2
exit 1
