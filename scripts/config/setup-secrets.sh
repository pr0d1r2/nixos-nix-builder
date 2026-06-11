#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SECRETS_DIR="$REPO_ROOT/secrets"

mkdir -p "$SECRETS_DIR"

if [ ! -f "$SECRETS_DIR/ssh_host_ed25519_key" ]; then
  echo "Generating SSH host key..."
  ssh-keygen -t ed25519 -f "$SECRETS_DIR/ssh_host_ed25519_key" -N "" -C "nixos-nix-builder"
else
  echo "SSH host key already exists, skipping."
fi

if [ ! -f "$SECRETS_DIR/authorized_keys" ]; then
  if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo "Copying your ed25519 public key to authorized_keys..."
    cp "$HOME/.ssh/id_ed25519.pub" "$SECRETS_DIR/authorized_keys"
  elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo "Copying your RSA public key to authorized_keys..."
    cp "$HOME/.ssh/id_rsa.pub" "$SECRETS_DIR/authorized_keys"
  else
    echo "No SSH public key found. Create authorized_keys manually:" >&2
    echo "  cp ~/.ssh/id_ed25519.pub $SECRETS_DIR/authorized_keys" >&2
    exit 1
  fi
else
  echo "authorized_keys already exists, skipping."
fi

if [ ! -f "$SECRETS_DIR/signing-key.sec" ]; then
  echo "Generating nix-serve signing keypair..."
  nix-store --generate-binary-cache-key \
    "nix-builder.local-1" \
    "$SECRETS_DIR/signing-key.sec" \
    "$SECRETS_DIR/signing-key.pub"
  echo "Public signing key:"
  cat "$SECRETS_DIR/signing-key.pub"
else
  echo "Signing keypair already exists, skipping."
fi

echo "Secrets ready in $SECRETS_DIR"
