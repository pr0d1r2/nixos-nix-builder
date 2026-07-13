# shellcheck shell=bash
# shellcheck disable=SC2154  # tier and target set by the calling fragment
prefix="storage-${tier}-mount"
mount_point="/mnt/storage-${tier}"

target_size=$(lsblk -lnb -o NAME,SIZE "$target" 2>/dev/null | awk '{ print $2 }')
target_size_h=$(numfmt --to=iec --suffix=B -- "${target_size:-0}" 2>/dev/null || echo "${target_size:-?} bytes")
parent_disk=$(lsblk -lno PKNAME "$target" 2>/dev/null | head -n1)
parent_model=$(lsblk -dno MODEL "/dev/${parent_disk:-none}" 2>/dev/null | sed 's/[[:space:]]*$//')

echo "$prefix: selected $target (${target_size_h}) on ${parent_disk:-?} (${parent_model:-unknown model})" >&2

if mount "$target" "$mount_point"; then
  chown 1000:1000 "$mount_point"
  echo "$prefix: mounted $target at $mount_point" >&2
else
  echo "$prefix: mount of $target failed" >&2
  exit 1
fi
