#!/usr/bin/env bats

@test "script is valid bash" {
  run bash -n scripts/config/setup-secrets.sh
  [ "$status" -eq 0 ]
}

@test "uses ssh-keygen for ed25519 host key" {
  run grep 'ssh-keygen -t ed25519' scripts/config/setup-secrets.sh
  [ "$status" -eq 0 ]
}

@test "checks for existing keys before generating" {
  run grep -c '! -f' scripts/config/setup-secrets.sh
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]
}

@test "generates nix-serve signing keypair" {
  run grep 'generate-binary-cache-key' scripts/config/setup-secrets.sh
  [ "$status" -eq 0 ]
}

@test "uses nix-builder.local-1 as signing key name" {
  run grep 'nix-builder.local-1' scripts/config/setup-secrets.sh
  [ "$status" -eq 0 ]
}
