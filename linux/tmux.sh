#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

TMUX_VERSION="3.6a"

# Skip if tmux is already installed at the desired version
if command_exists tmux && tmux -V | grep -q "$TMUX_VERSION"; then
  echo "tmux $TMUX_VERSION already installed, skipping"
  exit 0
fi

echo "Installing tmux $TMUX_VERSION from source..."

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"

curl -LO "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
tar xf "tmux-${TMUX_VERSION}.tar.gz"
cd "tmux-${TMUX_VERSION}"
./configure
make
sudo make install

rm -rf "$WORK_DIR"
echo "tmux $TMUX_VERSION installed successfully"
