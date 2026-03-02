#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Starting WSL bootstrap..."

# Configure WSL settings first
"$SCRIPT_DIR/wsl-config.sh"

"$SCRIPT_DIR/packages.sh"
"$SCRIPT_DIR/aws.sh"
"$SCRIPT_DIR/k8s.sh"
"$SCRIPT_DIR/github.sh"
"$SCRIPT_DIR/ssh.sh"
"$SCRIPT_DIR/lazyvim.sh"
"$SCRIPT_DIR/claude.sh"
"$SCRIPT_DIR/chezmoi.sh"

echo "Bootstrap complete."
