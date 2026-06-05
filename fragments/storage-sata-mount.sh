# shellcheck shell=bash
set -u

allowed=$(lsblk -dn -o NAME,TRAN 2>/dev/null |
    awk '$1 ~ /^sd[a-z]$/ && $2 != "usb" { print $1 }')

if [ -z "$allowed" ]; then
    echo "storage-sata-mount: no non-USB sd[a-z] disks detected; nothing to mount" >&2
    exit 0
fi

target=$(lsblk -lnpb -o NAME,TYPE,SIZE,FSTYPE,PKNAME 2>/dev/null |
    awk -v allowed="$allowed" -v fs="$STORAGE_FSTYPE" '
        BEGIN {
            n = split(allowed, a, /\n/)
            for (i = 1; i <= n; i++) if (a[i] != "") ok[a[i]] = 1
        }
        $2 == "part" && $4 == fs && ($5 in ok) { print $3, $1 }
    ' |
    sort -rn |
    head -n1 |
    awk '{ print $2 }')

if [ -z "$target" ]; then
    skipped=$(lsblk -lnpb -o NAME,TYPE,SIZE,FSTYPE,PKNAME 2>/dev/null |
        awk -v allowed="$allowed" -v fs="$STORAGE_FSTYPE" '
            BEGIN {
                n = split(allowed, a, /\n/)
                for (i = 1; i <= n; i++) if (a[i] != "") ok[a[i]] = 1
            }
            $2 == "part" && $4 != fs && $4 != "" && ($5 in ok) { print $1 "(" $4 ")" }
        ')
    if [ -n "$skipped" ]; then
        echo "storage-sata-mount: skipped non-$STORAGE_FSTYPE SATA partitions: $skipped" >&2
    fi
    echo "storage-sata-mount: no $STORAGE_FSTYPE partition found on any non-USB sd[a-z] disk; nothing to mount" >&2
    exit 0
fi

export tier=sata
