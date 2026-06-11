#!/usr/bin/env bats

@test "exits 0 when no storage available" {
  run env STORAGE="/nonexistent/path" bash -c '
        sed "s|/mnt/storage|/nonexistent/path|g" fragments/nix-store-overlay.sh | bash
    '
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ "no storage available" ]]
}

@test "guards bind-mount on rw-store existence" {
  grep -q 'rw-store.*not ready\|\.rw-store/store.*not.*exist\|! -d.*/nix/.rw-store' fragments/nix-store-overlay.sh
}

@test "checks for 9p host store mount" {
  grep -q 'mountpoint.*nix-host-store' fragments/nix-store-overlay.sh
}

@test "preStop fragment exists and is valid" {
  run bash -n fragments/nix-store-overlay-stop.sh
  [ "$status" -eq 0 ]
}

@test "preStop fragment umounts bind-mounts" {
  grep -q 'umount' fragments/nix-store-overlay-stop.sh
}
