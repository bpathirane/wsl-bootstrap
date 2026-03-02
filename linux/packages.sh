#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

sudo apt update

BASE_PACKAGES=(
  build-essential curl git unzip jq ripgrep fd-find fzf
  zsh tmux neovim direnv ca-certificates gnupg lsb-release
)

for pkg in "${BASE_PACKAGES[@]}"; do
  apt_install_if_missing "$pkg"
done

if ! command_exists starship; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

ensure_directory "$HOME/source/github_personal"

if ! command_exists docker; then
  echo "WARNING: docker CLI not found. Ensure Docker Desktop WSL integration is enabled."
fi
