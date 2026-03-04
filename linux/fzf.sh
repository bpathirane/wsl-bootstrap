#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

FZF_VERSION="0.70.0"

if command_exists fzf; then
  current="$(fzf --version | awk '{print $1}')"
  if [ "$current" = "$FZF_VERSION" ]; then
    echo "fzf $FZF_VERSION already installed"
    exit 0
  fi
  echo "Upgrading fzf from $current to $FZF_VERSION"
fi

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARCH="amd64" ;;
  arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${ARCH}.tar.gz" -o "$TMP/fzf.tar.gz"
tar -xzf "$TMP/fzf.tar.gz" -C "$TMP"
sudo install -m 755 "$TMP/fzf" /usr/local/bin/fzf

echo "fzf $FZF_VERSION installed"
