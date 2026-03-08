#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

TLDR_VERSION="1.8.1"

if command_exists tldr; then
  current="$(tldr --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)"
  if [ "$current" = "$TLDR_VERSION" ]; then
    echo "tldr $TLDR_VERSION already installed"
    exit 0
  fi
  echo "Upgrading tldr from $current to $TLDR_VERSION"
fi

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARCH="x86_64-musl" ;;
  arm64) ARCH="aarch64-musl" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/tealdeer-rs/tealdeer/releases/download/v${TLDR_VERSION}/tealdeer-linux-${ARCH}" -o "$TMP/tldr"
sudo install -m 755 "$TMP/tldr" /usr/local/bin/tldr

# Pre-fetch the page cache so tldr works immediately
tldr --update

echo "tldr $TLDR_VERSION installed"
