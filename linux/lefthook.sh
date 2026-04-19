#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

LEFTHOOK_VERSION="1.11.5"

if command_exists lefthook; then
  current="$(lefthook version 2>/dev/null | grep -oP '[\d.]+')"
  if [ "$current" = "$LEFTHOOK_VERSION" ]; then
    echo "lefthook $LEFTHOOK_VERSION already installed"
    exit 0
  fi
  echo "Upgrading lefthook from $current to $LEFTHOOK_VERSION"
fi

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARCH="x86_64" ;;
  arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/evilmartians/lefthook/releases/download/v${LEFTHOOK_VERSION}/lefthook_${LEFTHOOK_VERSION}_Linux_${ARCH}" -o "$TMP/lefthook"
sudo install -m 755 "$TMP/lefthook" /usr/local/bin/lefthook

echo "lefthook $LEFTHOOK_VERSION installed"
