#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

YAZI_VERSION="26.1.22"

if command_exists yazi; then
  current="$(yazi --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)"
  if [ "$current" = "$YAZI_VERSION" ]; then
    echo "yazi $YAZI_VERSION already installed"
    exit 0
  fi
  echo "Upgrading yazi from $current to $YAZI_VERSION"
fi

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) ARCH="x86_64-unknown-linux-gnu" ;;
  arm64) ARCH="aarch64-unknown-linux-gnu" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-${ARCH}.zip" -o "$TMP/yazi.zip"
unzip -q "$TMP/yazi.zip" -d "$TMP"

sudo install -m 755 "$TMP/yazi-${ARCH}/yazi" /usr/local/bin/yazi
sudo install -m 755 "$TMP/yazi-${ARCH}/ya"   /usr/local/bin/ya

# Optional dependencies for full preview support
apt_install_if_missing file
apt_install_if_missing ffmpegthumbnailer
apt_install_if_missing unar
apt_install_if_missing poppler-utils
apt_install_if_missing imagemagick

echo "yazi $YAZI_VERSION installed"
