#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

apt_update_if_stale

BASE_PACKAGES=(
  bat bison build-essential ca-certificates curl direnv fd-find
  git gnupg htop jq libevent-dev lsb-release ncurses-dev neovim pkg-config ripgrep unzip wslu zsh
)

for pkg in "${BASE_PACKAGES[@]}"; do
  apt_install_if_missing "$pkg"
done
