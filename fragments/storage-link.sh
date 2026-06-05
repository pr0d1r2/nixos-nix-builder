# shellcheck shell=bash
set -u

target=""
for candidate in /mnt/storage-nvme /mnt/storage-sata; do
    if mountpoint -q "$candidate"; then
        target="$candidate"
        break
    fi
done

if [ -z "$target" ]; then
    if mountpoint -q /mnt/storage 2>/dev/null; then
        umount /mnt/storage 2>/dev/null || true
    fi
    rm -rf /mnt/storage
    echo "storage-link: no storage tier mounted; /mnt/storage left absent" >&2
    exit 0
fi

if mountpoint -q /mnt/storage 2>/dev/null; then
    echo "storage-link: /mnt/storage already a mount point; skipping" >&2
    exit 0
fi

# Remove stale symlink or directory (ISO boot creates /mnt/storage as plain dir).
rm -rf /mnt/storage
mkdir -p /mnt/storage
mount --bind "$target" /mnt/storage
echo "storage-link: /mnt/storage bind-mounted from $target" >&2
