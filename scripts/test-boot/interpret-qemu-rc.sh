#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: interpret-qemu-rc.sh <exit-code>" >&2
    exit 2
fi

rc="$1"

case "$rc" in
    0)
        echo "QEMU exited cleanly (guest shutdown)."
        ;;
    1)
        echo "QEMU error (general failure)." >&2
        exit 1
        ;;
    137)
        echo "QEMU killed by SIGKILL." >&2
        exit 1
        ;;
    143)
        echo "QEMU terminated by SIGTERM." >&2
        exit 1
        ;;
    *)
        echo "QEMU exited with code $rc." >&2
        exit 1
        ;;
esac
