#!/usr/bin/env bats

@test "script references tier and target variables" {
  run grep -c 'tier' fragments/storage-mount-target.sh
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "mounts to correct mount point" {
  run grep '/mnt/storage-' fragments/storage-mount-target.sh
  [ "$status" -eq 0 ]
}

@test "chown uses numeric uid:gid not username" {
  run ! grep -q 'chown builder:builder' fragments/storage-mount-target.sh
  grep -q 'chown 1000:1000' fragments/storage-mount-target.sh
}
