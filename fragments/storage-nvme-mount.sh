# shellcheck shell=bash
set -u

target=""
for attempt in 1 2 3 4 5; do
    target=$(lsblk -lnpb -o NAME,TYPE,SIZE,FSTYPE,PKNAME 2>/dev/null |
        awk -v fs="$STORAGE_FSTYPE" '$2 == "part" && $4 == fs && $5 ~ /nvme/ { print $3, $1 }' |
        sort -rn |
        head -n1 |
        awk '{ print $2 }')
    [ -n "$target" ] && break
    echo "storage-nvme-mount: attempt $attempt: no NVMe $STORAGE_FSTYPE partition yet, retrying in 1s" >&2
    sleep 1
done

if [ -z "$target" ]; then
    skipped=$(lsblk -lnpb -o NAME,TYPE,SIZE,FSTYPE,PKNAME 2>/dev/null |
        awk -v fs="$STORAGE_FSTYPE" '$2 == "part" && $4 != fs && $4 != "" && $5 ~ /nvme/ { print $1 "(" $4 ")" }')
    if [ -n "$skipped" ]; then
        echo "storage-nvme-mount: skipped non-$STORAGE_FSTYPE NVMe partitions: $skipped" >&2
    fi
    echo "storage-nvme-mount: no $STORAGE_FSTYPE partition found on any NVMe disk; nothing to mount" >&2
    exit 0
fi

export tier=nvme
