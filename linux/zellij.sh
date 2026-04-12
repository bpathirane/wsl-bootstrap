#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

ZELLIJ_VERSION="0.44.1"

if command_exists zellij; then
  current="$(zellij --version | grep -oP '\d+\.\d+\.\d+')"
  if [ "$current" = "$ZELLIJ_VERSION" ]; then
    echo "zellij $ZELLIJ_VERSION already installed"
    exit 0
  fi
  echo "Upgrading zellij from $current to $ZELLIJ_VERSION"
fi

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARCH="x86_64-unknown-linux-musl" ;;
  arm64) ARCH="aarch64-unknown-linux-musl" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${ARCH}.tar.gz" -o "$TMP/zellij.tar.gz"
tar -xzf "$TMP/zellij.tar.gz" -C "$TMP"
sudo install -m 755 "$TMP/zellij" /usr/local/bin/zellij

echo "zellij $ZELLIJ_VERSION installed"
