#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

SOPS_VERSION="3.12.1"

if command_exists sops; then
  current="$(sops --version | grep -oP '[\d]+\.[\d]+\.[\d]+')"
  if [ "$current" = "$SOPS_VERSION" ]; then
    echo "sops $SOPS_VERSION already installed"
    exit 0
  fi
  echo "Upgrading sops from $current to $SOPS_VERSION"
fi

ARCH="$(dpkg --print-architecture)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops_${SOPS_VERSION}_${ARCH}.deb" -o "$TMP/sops.deb"
sudo dpkg -i "$TMP/sops.deb"

echo "sops $SOPS_VERSION installed"
