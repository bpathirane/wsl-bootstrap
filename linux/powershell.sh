#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if command_exists pwsh; then
  echo "PowerShell already installed: $(pwsh --version)"
  exit 0
fi

echo "Installing PowerShell..."

# Install prerequisites
apt_install_if_missing wget
apt_install_if_missing apt-transport-https
apt_install_if_missing software-properties-common

# Add Microsoft package signing key and repo
SOURCE_LIST=/etc/apt/sources.list.d/microsoft.list
if [ ! -f "$SOURCE_LIST" ]; then
  wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb
  sudo dpkg -i /tmp/packages-microsoft-prod.deb
  rm /tmp/packages-microsoft-prod.deb
fi

sudo apt update
sudo apt install -y powershell

echo "PowerShell installed: $(pwsh --version)"
