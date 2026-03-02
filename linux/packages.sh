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

# Wire starship into bash login shells via profile.d.
# Zsh init (eval "$(starship init zsh)") should live in your chezmoi-managed .zshrc.
if command_exists starship && [ ! -f /etc/profile.d/starship.sh ]; then
  echo 'eval "$(starship init bash)"' | sudo tee /etc/profile.d/starship.sh > /dev/null
  sudo chmod +x /etc/profile.d/starship.sh
fi

if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

ensure_directory "$HOME/source/github_personal"

if ! command_exists docker; then
  echo "WARNING: docker CLI not found. Ensure Docker Desktop WSL integration is enabled."
fi
