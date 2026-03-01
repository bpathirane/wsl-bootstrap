# WSL Bootstrap

Reproducible Ubuntu WSL setup for development.

## Quick Start (Windows PowerShell)

Run:

```powershell
$repo = "bpathirane"
$url = "https://raw.githubusercontent.com/$repo/wsl-bootstrap/main/setup-wsl.ps1"
$temp = "$env:TEMP\setup-wsl.ps1"

Invoke-WebRequest $url -OutFile $temp
powershell -ExecutionPolicy Bypass -File $temp
```

---

## Rebuild Mode

```powershell
powershell -ExecutionPolicy Bypass -File $temp -Rebuild
```

---

## Features

- Installs zsh, tmux, starship
- AWS CLI v2
- kubectl, kubectx, k9s
- GitHub CLI
- SSH key generation
- Chezmoi bootstrap
- Idempotent
- Safe to rerun

---

## Docker Desktop

Install separately:
https://www.docker.com/products/docker-desktop/

Enable WSL integration.

---

## Full Reset

```powershell
wsl --unregister Ubuntu
```
