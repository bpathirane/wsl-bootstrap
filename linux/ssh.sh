#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

SSH_DIR="$HOME/.ssh"
ensure_directory "$SSH_DIR"
chmod 700 "$SSH_DIR"

ssh-keyscan github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
ssh-keyscan ssh.dev.azure.com >> "$SSH_DIR/known_hosts" 2>/dev/null
chmod 644 "$SSH_DIR/known_hosts"

# ── SSH config ────────────────────────────────────────────────────────────────
cat > "$SSH_DIR/config" << 'EOF'
# Personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes

# Work GitHub
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

# Azure DevOps
Host ssh.dev.azure.com
    HostName ssh.dev.azure.com
    User git
    IdentityFile ~/.ssh/id_rsa_azdo
    IdentitiesOnly yes
EOF
chmod 600 "$SSH_DIR/config"

# ── Key generation ────────────────────────────────────────────────────────────
generate_key() {
  local key_file="$1" key_type="$2" comment="$3" label="$4"
  if [ ! -f "$key_file" ]; then
    echo "Generating $label key..."
    ssh-keygen -t "$key_type" -C "$comment" -f "$key_file" -N ""
  else
    echo "$label key already exists, skipping."
  fi
  chmod 600 "$key_file"
  chmod 644 "$key_file.pub"
}

generate_key "$SSH_DIR/id_ed25519_personal" ed25519 "$(whoami)@wsl-personal" "personal GitHub"
generate_key "$SSH_DIR/id_ed25519_work"     ed25519 "$(whoami)@wsl-work"     "work GitHub"
generate_key "$SSH_DIR/id_rsa_azdo"         rsa     "$(whoami)@wsl-azdo"     "Azure DevOps"

# ── Print public keys ─────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "Add these public keys to the respective accounts:"
echo ""

echo "── Personal GitHub (github.com) ─────────"
cat "$SSH_DIR/id_ed25519_personal.pub"
echo ""

echo "── Work GitHub (github.com-work) ────────"
cat "$SSH_DIR/id_ed25519_work.pub"
echo ""

echo "── Azure DevOps ─────────────────────────"
cat "$SSH_DIR/id_rsa_azdo.pub"
echo "========================================"
echo ""
read -p "Press ENTER after adding all keys to their respective accounts..."

# ── Switch bootstrap repo remote to SSH ───────────────────────────────────────
BOOTSTRAP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -d "$BOOTSTRAP_DIR/.git" ]; then
  current_remote="$(git -C "$BOOTSTRAP_DIR" remote get-url origin 2>/dev/null || true)"
  if echo "$current_remote" | grep -q "^https://github.com/"; then
    ssh_remote="$(echo "$current_remote" | sed 's|https://github.com/|git@github.com:|')"
    git -C "$BOOTSTRAP_DIR" remote set-url origin "$ssh_remote"
    echo "Switched bootstrap remote: $current_remote → $ssh_remote"
  else
    echo "Bootstrap remote already using SSH: $current_remote"
  fi
fi
