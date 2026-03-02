#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# lazygit — required by LazyVim's git integration
if ! command_exists lazygit; then
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    | sudo tar xz -C /usr/local/bin lazygit
fi

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
  npm install -g tree-sitter-cli
fi

# LazyVim starter config
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "Installing LazyVim starter..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
  echo "Bootstrapping LazyVim plugins (headless)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
else
  echo "Neovim config already exists, skipping LazyVim starter."
fi
