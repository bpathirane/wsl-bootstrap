#!/usr/bin/env bash
# validate.sh — WSL bootstrap validation
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ── Colours ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

PASS="${GREEN}✔${RESET}"; FAIL="${RED}✘${RESET}"; WARN="${YELLOW}⚠${RESET}"

pass=0; fail=0; warn=0

_pass() { echo -e "  ${PASS}  $1"; (( pass++ )) || true; }
_fail() { echo -e "  ${FAIL}  $1"; (( fail++ )) || true; }
_warn() { echo -e "  ${WARN}  $1"; (( warn++ )) || true; }
_section() { echo -e "\n${BOLD}${CYAN}▶ $1${RESET}"; }

# Check a command exists and optionally validate its version output
# Usage: check_tool NAME CMD VERSION_CMD EXPECTED
check_tool() {
  local name="$1" cmd="$2" version_cmd="$3" expected="${4:-}"
  if ! command_exists "$cmd"; then
    _fail "$name — not found"
    return
  fi
  local version
  version="$(eval "$version_cmd" 2>/dev/null | head -1)"
  if [ -n "$expected" ]; then
    if echo "$version" | grep -qF "$expected"; then
      _pass "$name — $version"
    else
      _fail "$name — expected $expected, got: $version"
    fi
  else
    _pass "$name — $version"
  fi
}

# Check a command exists and version is >= minimum (semver/calver via sort -V)
# Usage: check_tool_min NAME CMD VERSION_CMD MIN_VERSION
check_tool_min() {
  local name="$1" cmd="$2" version_cmd="$3" min="$4"
  if ! command_exists "$cmd"; then
    _fail "$name — not found"
    return
  fi
  local version
  version="$(eval "$version_cmd" 2>/dev/null | grep -oP '\d+(?:\.\d+)+[a-z]?' | head -1)"
  if [ -z "$version" ]; then
    _warn "$name — could not parse version"
    return
  fi
  local lowest
  lowest="$(printf '%s\n%s' "$min" "$version" | sort -V | head -1)"
  if [ "$lowest" = "$min" ]; then
    _pass "$name — $version (>= $min)"
  else
    _fail "$name — $version (need >= $min)"
  fi
}

# ── 1. Tool versions ────────────────────────────────────────────────────────
_section "Tool versions"

# Pinned versions from install scripts
LAZYGIT_VERSION="0.59.0"
FZF_VERSION="0.70.0"
TMUX_VERSION="3.6a"
YAZI_VERSION="26.1.22"
TLDR_VERSION="1.8.1"

check_tool "neovim"    nvim        "nvim --version"                             "v0."
check_tool "node"      node        "node --version"                             ""
check_tool "git"       git         "git --version"                              ""
check_tool "gh"        gh          "gh --version"                               ""
check_tool_min "lazygit"   lazygit     "lazygit --version"                          "$LAZYGIT_VERSION"
check_tool_min "fzf"       fzf         "fzf --version"                              "$FZF_VERSION"
check_tool_min "tmux"      tmux        "tmux -V"                                    "$TMUX_VERSION"
check_tool "starship"  starship    "starship --version"                         ""
check_tool "zoxide"    zoxide      "zoxide --version"                           ""
check_tool "fd"        fdfind      "fdfind --version"                           ""
check_tool "ripgrep"   rg          "rg --version"                               ""
check_tool "bat"       batcat      "batcat --version"                           ""
check_tool "tree-sitter" tree-sitter "tree-sitter --version"                   ""
check_tool "lazyvim"   nvim        "nvim --version | grep -i lazyvim || true"  ""
check_tool "claude"    claude      "claude --version"                           ""
check_tool "chezmoi"   chezmoi     "chezmoi --version"                         ""
check_tool "direnv"    direnv      "direnv --version"                          ""
check_tool "sops"      sops        "sops --version"                            ""
check_tool_min "yazi"      yazi        "yazi --version"                            "$YAZI_VERSION"
check_tool_min "tldr"      tldr        "tldr --version"                            "$TLDR_VERSION"
check_tool "jq"        jq          "jq --version"                              ""
check_tool "win32yank" win32yank.exe "echo WSL clipboard provider"             ""

# Neovim: confirm it's from GitHub (not apt)
_section "Neovim install source"
if command_exists nvim; then
  nvim_path="$(which nvim)"
  nvim_ver="$(nvim --version | head -1)"
  if [ "$nvim_path" = "/usr/local/bin/nvim" ] && [ -f /opt/nvim-linux-x86_64/bin/nvim ]; then
    _pass "nvim from GitHub release at $nvim_path ($nvim_ver)"
  elif dpkg -s neovim >/dev/null 2>&1; then
    _fail "nvim is from apt package — run lazyvim.sh to upgrade ($nvim_ver)"
  else
    _warn "nvim at $nvim_path — source unknown ($nvim_ver)"
  fi
fi

# ── 2. Kubernetes tools ───────────────────────────────────────────────────────
_section "Kubernetes tools"

check_tool "kubectl"  kubectl  "kubectl version --client --short 2>/dev/null || kubectl version --client"  ""
check_tool "kind"     kind     "kind version"                                                              ""
check_tool "k9s"      k9s      "k9s version"                                                              ""

# kubectx / kubens are symlinks into /opt/kubectx — check both the dir and the commands
if [ -d "/opt/kubectx" ]; then
  _pass "kubectx repo present at /opt/kubectx"
else
  _fail "kubectx repo missing at /opt/kubectx — run k8s.sh"
fi
check_tool "kubectx (kctx)"  kctx  "kctx --help 2>&1 | head -1 || echo ok"  ""
check_tool "kubens (kns)"    kns   "kns --help 2>&1 | head -1 || echo ok"   ""

# ── 3. Shell ─────────────────────────────────────────────────────────────────
_section "Shell"
default_shell="$(getent passwd "$(whoami)" | cut -d: -f7)"
if echo "$default_shell" | grep -q zsh; then
  _pass "Default shell is zsh ($default_shell)"
else
  _fail "Default shell is not zsh: $default_shell"
fi
if command_exists zsh; then
  _pass "zsh available: $(zsh --version)"
fi

# ── 3. WSL integration ────────────────────────────────────────────────────────
_section "WSL integration"

# /mnt/c mounted
if [ -f /mnt/c/Windows/System32/reg.exe ]; then
  _pass "/mnt/c is mounted (Windows drives accessible)"
else
  _fail "/mnt/c is not mounted — automount may be disabled; run: sudo mount -t drvfs C: /mnt/c"
fi

# wsl.conf settings
if [ -f /etc/wsl.conf ]; then
  automount="$(grep -E '^enabled\s*=' /etc/wsl.conf | tail -1 | tr -d ' ')"
  win_path="$(grep 'appendWindowsPath' /etc/wsl.conf | tr -d ' ' || echo '')"
  if grep -qE 'enabled\s*=\s*true' /etc/wsl.conf && grep -A3 '\[automount\]' /etc/wsl.conf | grep -q 'enabled = true'; then
    _pass "wsl.conf: automount enabled"
  else
    _warn "wsl.conf: automount may be disabled"
  fi
  if echo "$win_path" | grep -q 'false'; then
    _pass "wsl.conf: appendWindowsPath = false (Windows tools symlinked instead)"
  else
    _warn "wsl.conf: appendWindowsPath = true (Windows PATH injected)"
  fi
fi

# Windows tool symlinks
for tool in reg.exe chcp.com pwsh.exe clip.exe; do
  if [ -L /usr/local/bin/$tool ] && [ -e /usr/local/bin/$tool ]; then
    target="$(readlink /usr/local/bin/$tool)"
    _pass "$tool symlinked → $target"
  else
    _fail "$tool not symlinked in /usr/local/bin — run wsl-config.sh"
  fi
done

# wslview
if command_exists wslview; then
  _pass "wslview available: $(wslview --version 2>&1 | head -1)"
else
  _fail "wslview not found (install wslu)"
fi

# systemd
if [ "$(ps -p 1 -o comm=)" = "systemd" ]; then
  _pass "systemd is running as PID 1"
else
  _warn "systemd is not PID 1 (boot.systemd may be off)"
fi

# ── 4. Git authentication ─────────────────────────────────────────────────────
_section "Git authentication"

if ! command_exists gh; then
  _fail "gh not installed — skipping auth checks"
else
  gh_status="$(gh auth status 2>&1)"
  if echo "$gh_status" | grep -q "Logged in"; then
    gh_user="$(echo "$gh_status" | grep -oP 'account \K\S+' | head -1)"
    _pass "gh: authenticated as $gh_user"
  else
    _fail "gh: not authenticated — run: gh auth login"
  fi

  if echo "$gh_status" | grep -q "Token scopes:"; then
    scopes="$(echo "$gh_status" | grep "Token scopes:" | head -1)"
    _pass "gh: $scopes"
  fi
fi

# SSH keys — check each expected key
declare -A SSH_KEYS=(
  ["id_ed25519_personal"]="personal GitHub (github.com)"
  ["id_ed25519_work"]="work GitHub (github.com-work)"
  ["id_rsa_azdo"]="Azure DevOps"
)
for key in "${!SSH_KEYS[@]}"; do
  label="${SSH_KEYS[$key]}"
  if [ -f "$HOME/.ssh/$key" ]; then
    _pass "SSH key present: $key ($label)"
  else
    _fail "SSH key missing: ~/.ssh/$key ($label) — run ssh.sh"
  fi
done

# SSH config
if [ -f "$HOME/.ssh/config" ]; then
  _pass "~/.ssh/config exists"
else
  _fail "~/.ssh/config missing — run ssh.sh"
fi

# Test personal GitHub auth
ssh_personal="$(ssh -T git@github.com 2>&1 || true)"
if echo "$ssh_personal" | grep -q "successfully authenticated"; then
  gh_user="$(echo "$ssh_personal" | grep -oP "Hi \K\S+" | tr -d '!')"
  _pass "SSH: personal GitHub authenticated as $gh_user"
else
  _warn "SSH: personal GitHub not authenticated (add ~/.ssh/id_ed25519_personal.pub to github.com)"
fi

# Test work GitHub auth
ssh_work="$(ssh -T git@github.com-work 2>&1 || true)"
if echo "$ssh_work" | grep -q "successfully authenticated"; then
  gh_user="$(echo "$ssh_work" | grep -oP "Hi \K\S+" | tr -d '!')"
  _pass "SSH: work GitHub authenticated as $gh_user"
else
  _warn "SSH: work GitHub not authenticated (add ~/.ssh/id_ed25519_work.pub to work github.com)"
fi

# Git identity
git_name="$(git config --global user.name 2>/dev/null || true)"
git_email="$(git config --global user.email 2>/dev/null || true)"
if [ -n "$git_name" ] && [ -n "$git_email" ]; then
  _pass "Git identity: $git_name <$git_email>"
else
  _fail "Git identity not configured — run: git config --global user.name/email"
fi

# ── 5. wslview browser test ───────────────────────────────────────────────────
_section "wslview browser test"

if ! command_exists wslview || ! [ -f /mnt/c/Windows/System32/reg.exe ]; then
  _fail "wslview or /mnt/c not available — skipping browser test"
else
  PORT="${WSLVIEW_TEST_PORT:-19876}"
  CALLBACK_FILE="$(mktemp)"
  trap 'rm -f "$CALLBACK_FILE"' EXIT

  # Embedded Python HTTP server: serves a page that auto-fetches /callback,
  # then waits up to 20s for the callback before timing out.
  python3 - "$PORT" "$CALLBACK_FILE" << 'PYEOF' &
import sys, http.server, threading, os, time

port = int(sys.argv[1])
callback_file = sys.argv[2]

HTML = b"""<!DOCTYPE html>
<html>
<head><title>wslview test</title></head>
<body>
<h2>WSL browser test</h2>
<p id="status">Sending callback...</p>
<script>
  fetch('/callback', { method: 'POST', body: 'ok' })
    .then(() => { document.getElementById('status').textContent = 'Callback sent! You can close this tab.'; })
    .catch(e => { document.getElementById('status').textContent = 'Error: ' + e; });
</script>
</body>
</html>"""

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        self.wfile.write(HTML)
    def do_POST(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'ok')
        open(callback_file, 'w').write('received')

server = http.server.HTTPServer(('0.0.0.0', port), Handler)
server.timeout = 1

deadline = time.time() + 25
while time.time() < deadline:
    server.handle_request()
    if os.path.exists(callback_file) and open(callback_file).read() == 'received':
        break

server.server_close()
PYEOF

  SERVER_PID=$!
  sleep 0.5  # let the server start

  echo -e "  ${CYAN}→ Opening http://localhost:${PORT} via wslview...${RESET}"
  wslview "http://localhost:${PORT}" 2>/dev/null || true

  # Poll for callback (max 20s)
  elapsed=0
  received=false
  while [ $elapsed -lt 20 ]; do
    if [ -s "$CALLBACK_FILE" ] && grep -q "received" "$CALLBACK_FILE" 2>/dev/null; then
      received=true
      break
    fi
    sleep 1
    (( elapsed++ )) || true
  done

  kill "$SERVER_PID" 2>/dev/null || true

  if $received; then
    _pass "wslview: browser opened and callback received in ${elapsed}s"
  else
    _fail "wslview: no callback received within 20s (browser may not have opened, or localhost not reachable from Windows)"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}────────────────────────────────────────${RESET}"
echo -e "${BOLD}Results:${RESET}  ${GREEN}${pass} passed${RESET}  ${RED}${fail} failed${RESET}  ${YELLOW}${warn} warnings${RESET}"
echo ""
if [ "$fail" -gt 0 ]; then
  exit 1
fi
