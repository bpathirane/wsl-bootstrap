#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if ! command_exists chezmoi; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
fi

if [ -z "${GITHUB_USER}" ]; then
  if [ -t 0 ]; then
    read -rp "Enter your GitHub username: " GITHUB_USER
  else
    echo "ERROR: GITHUB_USER is not set and no terminal available for input." >&2
    exit 1
  fi
fi

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
  echo "Initializing chezmoi from git@github.com:${GITHUB_USER}/dotfiles.git ..."
  if [ -t 0 ]; then
    echo "Ensure your SSH key is added to GitHub before proceeding."
    read -p "Press ENTER to continue..."
  fi
  chezmoi init --apply "git@github.com:${GITHUB_USER}/dotfiles.git"
else
  echo "Chezmoi already initialized, re-applying dotfiles..."
  chezmoi apply
fi
