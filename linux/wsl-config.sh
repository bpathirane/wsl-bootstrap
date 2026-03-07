#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Configuring WSL settings..."

# Read configuration from environment variables (set by PowerShell)
DISABLE_WINDOWS_PATH=${DISABLE_WINDOWS_PATH:-false}
DISABLE_AUTO_MOUNT=${DISABLE_AUTO_MOUNT:-false}

# Create /etc/wsl.conf if it doesn't exist
if [ ! -f /etc/wsl.conf ]; then
    echo "Creating /etc/wsl.conf..."
    sudo touch /etc/wsl.conf
fi

# Backup existing config
if [ -f /etc/wsl.conf ] && [ -s /etc/wsl.conf ]; then
    sudo cp /etc/wsl.conf /etc/wsl.conf.backup
    echo "Backed up existing config to /etc/wsl.conf.backup"
fi

# Build configuration
CONFIG=""

# Configure interop section (Windows PATH)
CONFIG+="[interop]\n"
CONFIG+="enabled = true\n"
if [ "$DISABLE_WINDOWS_PATH" = "true" ]; then
    echo "  - Disabling Windows PATH injection"
    CONFIG+="appendWindowsPath = false\n"
else
    echo "  - Enabling Windows PATH injection"
    CONFIG+="appendWindowsPath = true\n"
fi
CONFIG+="\n"

# Configure automount section (Windows drives)
if [ "$DISABLE_AUTO_MOUNT" = "true" ]; then
    echo "  - Disabling auto-mount of Windows drives"
    CONFIG+="[automount]\n"
    CONFIG+="enabled = false\n"
    CONFIG+="\n"
else
    echo "  - Keeping auto-mount of Windows drives enabled (default)"
    CONFIG+="[automount]\n"
    CONFIG+="enabled = true\n"
    CONFIG+="root = /mnt/\n"
    CONFIG+="options = \"metadata,umask=22\"\n"
    CONFIG+="\n"
fi

# Add boot section for systemd (useful for modern WSL)
CONFIG+="[boot]\n"
CONFIG+="systemd = true\n"
CONFIG+="\n"

# Add user section so the default user is preserved after rewrite
CONFIG+="[user]\n"
CONFIG+="default = $(whoami)\n"
CONFIG+="\n"

# Add network section
CONFIG+="[network]\n"
CONFIG+="generateResolvConf = true\n"
CONFIG+="\n"

# Write configuration
echo -e "$CONFIG" | sudo tee /etc/wsl.conf > /dev/null

echo "WSL configuration updated."
echo ""
echo "Current /etc/wsl.conf:"
echo "---"
cat /etc/wsl.conf
echo "---"
echo ""
echo "NOTE: WSL must be restarted for changes to take effect."
echo "Run: wsl --shutdown (from PowerShell/CMD)"
