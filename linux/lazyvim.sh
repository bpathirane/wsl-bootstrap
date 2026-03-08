#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# Neovim — install latest stable from GitHub releases (apt ships outdated versions)
# Remove apt-installed neovim if present to avoid conflicts
if dpkg -s neovim >/dev/null 2>&1; then
  sudo apt remove -y neovim
fi

NVIM_LATEST="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | cut -d'"' -f4)"
NVIM_CURRENT="$(nvim --version 2>/dev/null | head -1 | grep -oP 'v[\d.]+')"

if [ "$NVIM_CURRENT" != "$NVIM_LATEST" ]; then
  echo "Installing Neovim ${NVIM_LATEST} (current: ${NVIM_CURRENT:-none})..."
  NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
  TMP_DIR="$(mktemp -d)"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${NVIM_ARCHIVE}" -o "${TMP_DIR}/${NVIM_ARCHIVE}"
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf "${TMP_DIR}/${NVIM_ARCHIVE}"
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm -rf "${TMP_DIR}"
  echo "Neovim ${NVIM_LATEST} installed."
else
  echo "Neovim ${NVIM_CURRENT} is already up to date."
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
