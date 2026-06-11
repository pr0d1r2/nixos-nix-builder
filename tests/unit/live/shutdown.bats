#!/usr/bin/env bats

setup() {
  tmp="$(mktemp -d)"
  export PATH="$tmp:$PATH"
  cat >"$tmp/ssh" <<'STUB'
#!/bin/sh
echo "ssh: $*" >&2
STUB
  chmod +x "$tmp/ssh"
  mkdir -p "$tmp/scripts/lib"
  cat >"$tmp/scripts/lib/find-builder.sh" <<'STUB'
#!/bin/sh
echo "root@nix-builder.local"
STUB
  chmod +x "$tmp/scripts/lib/find-builder.sh"
}

teardown() {
  rm -rf "$tmp"
}

@test "sends shutdown to builder" {
  run bash -c "
        sed 's|REPO_ROOT=.*|REPO_ROOT=\"$tmp\"|' scripts/live/shutdown.sh | bash
    "
  [ "$status" -eq 0 ]
  [[ "${lines[*]}" =~ shutdown:\ sending\ shutdown\ to\ root@nix-builder.local ]]
  [[ "${lines[*]}" =~ shutdown:\ command\ sent ]]
}
