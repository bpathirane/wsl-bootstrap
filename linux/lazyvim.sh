#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# Node.js LTS — required by Mason (LazyVim LSP installer) for many language servers
if ! command_exists node; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# fd — LazyVim expects the binary to be named `fd`; Ubuntu apt installs it as `fdfind`
if command_exists fdfind && ! command_exists fd; then
  ensure_directory "$HOME/.local/bin"
  ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
  export PATH="$HOME/.local/bin:$PATH"
fi

# tree-sitter CLI — used by LazyVim/nvim-treesitter to compile parsers
if ! command_exists tree-sitter; then
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
  npm install -g tree-sitter-cli
fi

# LazyVim starter config
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "Installing LazyVim starter..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
else
  echo "Neovim config already exists, skipping LazyVim starter."
fi
