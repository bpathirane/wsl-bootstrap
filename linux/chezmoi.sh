#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if ! command_exists chezmoi; then
  sh -c "$(curl -fsLS get.chezmoi.io)"
fi

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  echo "Initializing chezmoi..."
  echo "Ensure your SSH key is added to GitHub before proceeding."
  read -p "Press ENTER to continue..."
  chezmoi init --apply git@github.com:bpathirane/dotfiles.git
else
  echo "Chezmoi already initialized."
fi
