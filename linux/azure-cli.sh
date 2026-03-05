#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if command_exists az; then
  echo "Azure CLI already installed: $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
  exit 0
fi

echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
