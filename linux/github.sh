#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if ! command_exists gh; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

  sudo apt update
  sudo apt install -y gh
fi
