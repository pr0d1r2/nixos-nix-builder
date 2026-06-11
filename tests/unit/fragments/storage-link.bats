#!/usr/bin/env bats

@test "removes symlink when no tier mounted" {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/mnt"
  cat >"$tmp/mountpoint" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$tmp/mountpoint"
  run env PATH="$tmp:$PATH" bash -c "
        sed 's|/mnt/storage|$tmp/mnt/storage|g' fragments/storage-link.sh | bash
    "
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "no storage tier" ]]
  rm -rf "$tmp"
}

@test "replaces empty directory with bind mount" {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/mnt/storage" "$tmp/mnt/storage-nvme"
  cat >"$tmp/mountpoint" <<'SCRIPT'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in */storage-nvme) exit 0 ;; esac
done
exit 1
SCRIPT
  cat >"$tmp/mount" <<'SCRIPT'
#!/bin/sh
exit 0
SCRIPT
  chmod +x "$tmp/mountpoint" "$tmp/mount"
  run env PATH="$tmp:$PATH" bash -c "
        sed 's|/mnt/storage|$tmp/mnt/storage|g' fragments/storage-link.sh | bash
    "
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "bind-mounted" ]]
  [ -d "$tmp/mnt/storage" ]
  rm -rf "$tmp"
}

@test "replaces non-empty directory with bind mount" {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/mnt/storage/nix-builds" "$tmp/mnt/storage-nvme"
  cat >"$tmp/mountpoint" <<'SCRIPT'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in */storage-nvme) exit 0 ;; esac
done
exit 1
SCRIPT
  cat >"$tmp/mount" <<'SCRIPT'
#!/bin/sh
exit 0
SCRIPT
  chmod +x "$tmp/mountpoint" "$tmp/mount"
  run env PATH="$tmp:$PATH" bash -c "
        sed 's|/mnt/storage|$tmp/mnt/storage|g' fragments/storage-link.sh | bash
    "
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "bind-mounted" ]]
  [ -d "$tmp/mnt/storage" ]
  rm -rf "$tmp"
}

@test "refuses to touch mount point" {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/mnt/storage" "$tmp/mnt/storage-nvme"
  cat >"$tmp/mountpoint" <<'SCRIPT'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in
        */storage-nvme) exit 0 ;;
        */storage) exit 0 ;;
    esac
done
exit 1
SCRIPT
  chmod +x "$tmp/mountpoint"
  run env PATH="$tmp:$PATH" bash -c "
        sed 's|/mnt/storage|$tmp/mnt/storage|g' fragments/storage-link.sh | bash
    "
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "mount point" ]]
  [ -d "$tmp/mnt/storage" ]
  [ ! -L "$tmp/mnt/storage" ]
  rm -rf "$tmp"
}
