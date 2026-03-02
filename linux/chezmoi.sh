#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

export PATH="$HOME/bin:$PATH"

if ! command_exists chezmoi; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/bin"
fi

if [ -z "${GITHUB_USER}" ]; then
  read -rp "Enter your GitHub username: " GITHUB_USER
fi

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  echo "Initializing chezmoi..."
  echo "Ensure your SSH key is added to GitHub before proceeding."
  read -p "Press ENTER to continue..."
  chezmoi init --apply "git@github.com:${GITHUB_USER}/dotfiles.git"
else
  echo "Chezmoi already initialized, re-applying dotfiles..."
  chezmoi apply
fi
