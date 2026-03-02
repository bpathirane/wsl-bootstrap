#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# Claude Code CLI — requires Node.js (installed by lazyvim.sh)
if ! command_exists claude; then
  echo "Installing Claude Code CLI..."
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
  npm install -g @anthropic-ai/claude-code
fi
