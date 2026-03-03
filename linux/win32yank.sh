#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# win32yank — Windows clipboard provider for Neovim in WSL
if ! command_exists win32yank.exe; then
  WIN32YANK_VERSION=$(curl -s "https://api.github.com/repos/equalsraf/win32yank/releases/latest" \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  curl -fsSL "https://github.com/equalsraf/win32yank/releases/download/v${WIN32YANK_VERSION}/win32yank-x64.zip" \
    -o /tmp/win32yank.zip
  unzip -o /tmp/win32yank.zip -d /tmp/win32yank
  sudo cp /tmp/win32yank/win32yank.exe /usr/local/bin/
  sudo chmod +x /usr/local/bin/win32yank.exe
  rm -rf /tmp/win32yank /tmp/win32yank.zip
fi
