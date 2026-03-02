# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Automates creation and provisioning of named WSL2 Ubuntu instances on Windows. The Windows-side PowerShell script creates/imports a WSL instance, then delegates to a Linux-side bash bootstrap that runs inside that instance.

## Entry Points

- **`setup-wsl.ps1`** — Windows entry point. Accepts params: `-DistroName`, `-VhdPath`, `-VhdSizeGB`, `-DisableWindowsPath`, `-DisableAutoMount`, `-Rebuild`, `-GitHubUsername`, `-BootstrapRepoName`. Clones this repo inside the new WSL instance and calls `linux/install.sh`.
- **`linux/install.sh`** — Linux entry point. Runs sequentially: `wsl-config.sh` → `packages.sh` → `aws.sh` → `k8s.sh` → `github.sh` → `ssh.sh` → `chezmoi.sh`.
- **`manage-vhd.ps1`** — Standalone VHD management utility. Actions: `Info`, `Compact`, `Resize`, `Move`.

## Linux Script Architecture

All `linux/` scripts source `lib.sh` for shared helpers:
- `command_exists <cmd>` — checks if a binary is on PATH
- `apt_install_if_missing <pkg>` — skips install if already installed (idempotency)
- `ensure_directory <path>` — mkdir -p wrapper

Each tool script (`aws.sh`, `k8s.sh`, `github.sh`, `chezmoi.sh`) uses `command_exists` guards to make all installs idempotent — safe to rerun without re-installing.

## Environment Variables (PowerShell → Linux)

`setup-wsl.ps1` passes configuration to `install.sh` via env vars:
- `DISABLE_WINDOWS_PATH` — read by `wsl-config.sh` to set `appendWindowsPath` in `/etc/wsl.conf`
- `DISABLE_AUTO_MOUNT` — read by `wsl-config.sh` to set automount in `/etc/wsl.conf`
- `GITHUB_USER` — read by `chezmoi.sh` to init dotfiles from `git@github.com:<user>/dotfiles.git`

## Default Behavior

- Instance name: `Ubuntu-Dev`
- Base distro: `Ubuntu-24.04`
- VHD location: `%LOCALAPPDATA%\WSL\<DistroName>`
- VHD max size: 256 GB
- Windows PATH injection: **disabled** (isolated environment)
- Windows drive auto-mount: **disabled**
- systemd: enabled in `/etc/wsl.conf`

## Running the Scripts

```powershell
# Basic setup (from PowerShell as Administrator)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1

# Install a specific distro directly (name must appear in `wsl --list --online`)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Debian"

# Custom instance on D: drive cloned from a chosen base distro
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Dev" -BaseDistro "Ubuntu-24.04" -VhdPath "D:\WSL\Dev" -VhdSizeGB 512

# Rebuild (destroys all data in instance)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Ubuntu-Dev" -Rebuild

# VHD management
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Compact
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Resize -NewSizeGB 512
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Move -NewPath "D:\WSL\Ubuntu-Dev"
```

```bash
# Re-run Linux bootstrap manually inside WSL (all scripts are idempotent)
cd ~/wsl-bootstrap/linux && chmod +x *.sh && ./install.sh
```

## Custom Instance Creation

`setup-wsl.ps1` queries `wsl --list --online` at runtime to discover directly installable distros. If `$DistroName` matches a known online distro, it installs it with `wsl --install -d` directly. Otherwise it treats the name as a custom instance: it installs `$BaseDistro` if not already present locally, exports it as a `.tar`, then imports it under `$DistroName`. This is the mechanism that enables multiple named instances from any available base distro.
