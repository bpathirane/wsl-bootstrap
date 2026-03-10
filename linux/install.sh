#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Starting WSL bootstrap..."

# Configure WSL settings first
"$SCRIPT_DIR/wsl-config.sh"

# Install apt packages
"$SCRIPT_DIR/install-packages.sh"

# tmux from source (needs build-essential, libevent-dev, ncurses-dev from apt)
"$SCRIPT_DIR/tmux.sh"

# Starship prompt
if ! command_exists starship; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
# Wire starship into bash login shells via profile.d.
# Zsh init (eval "$(starship init zsh)") should live in your chezmoi-managed .zshrc.
if command_exists starship && [ ! -f /etc/profile.d/starship.sh ]; then
  echo 'eval "$(starship init bash)"' | sudo tee /etc/profile.d/starship.sh > /dev/null
  sudo chmod +x /etc/profile.d/starship.sh
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

ensure_directory "$HOME/source/github_personal"

if ! command_exists docker; then
  echo "WARNING: docker CLI not found. Ensure Docker Desktop WSL integration is enabled."
fi

# Tool installs
"$SCRIPT_DIR/azure-cli.sh"
"$SCRIPT_DIR/aws.sh"
"$SCRIPT_DIR/k8s.sh"
"$SCRIPT_DIR/github.sh"
"$SCRIPT_DIR/ssh.sh"
"$SCRIPT_DIR/win32yank.sh"
"$SCRIPT_DIR/fzf.sh"
"$SCRIPT_DIR/lazygit.sh"
"$SCRIPT_DIR/yazi.sh"
"$SCRIPT_DIR/tldr.sh"
"$SCRIPT_DIR/zoxide.sh"
"$SCRIPT_DIR/lazyvim.sh"
"$SCRIPT_DIR/bun.sh"
"$SCRIPT_DIR/claude.sh"
"$SCRIPT_DIR/sops.sh"
"$SCRIPT_DIR/chezmoi.sh"

echo "Bootstrap complete."
