#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_ed25519"

ensure_directory "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$KEY_FILE" ]; then
  ssh-keygen -t ed25519 -C "$(whoami)@wsl" -f "$KEY_FILE" -N ""
fi

chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE.pub"

echo ""
echo "Add this SSH key to GitHub:"
echo "----------------------------------------"
cat "$KEY_FILE.pub"
echo "----------------------------------------"
echo ""
read -p "Press ENTER after adding the key to GitHub..."
