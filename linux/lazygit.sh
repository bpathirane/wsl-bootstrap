#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

LAZYGIT_VERSION="0.59.0"

if command_exists lazygit; then
  current="$(lazygit --version | grep -oP 'version=\K[^,]+')"
  if [ "$current" = "$LAZYGIT_VERSION" ]; then
    echo "lazygit $LAZYGIT_VERSION already installed"
    exit 0
  fi
  echo "Upgrading lazygit from $current to $LAZYGIT_VERSION"
fi

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" -o "$TMP/lazygit.tar.gz"
tar -xzf "$TMP/lazygit.tar.gz" -C "$TMP"
sudo install -m 755 "$TMP/lazygit" /usr/local/bin/lazygit

echo "lazygit $LAZYGIT_VERSION installed"
