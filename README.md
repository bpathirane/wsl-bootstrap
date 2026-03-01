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

This creates a WSL instance named `Ubuntu-Dev` (default).

---

## Custom Instance Name

To avoid conflicts with existing WSL instances, specify a custom name:

```powershell
powershell -ExecutionPolicy Bypass -File $temp -DistroName "MyDevEnv"
```

You can have multiple instances with different names:

```powershell
# Work environment
powershell -ExecutionPolicy Bypass -File $temp -DistroName "Work-Dev"

# Personal projects
powershell -ExecutionPolicy Bypass -File $temp -DistroName "Personal-Dev"
```

---

## VHD Customization

### Custom VHD Location

Store the VHD on a different drive (useful for SSDs or drives with more space):

```powershell
# Store on D: drive
powershell -ExecutionPolicy Bypass -File $temp `
  -DistroName "Ubuntu-Dev" `
  -VhdPath "D:\WSL\Ubuntu-Dev"

# Store on external drive
powershell -ExecutionPolicy Bypass -File $temp `
  -DistroName "Work-Dev" `
  -VhdPath "E:\Development\WSL\Work-Dev"
```

**Default location:** `%LOCALAPPDATA%\WSL\<DistroName>` (typically `C:\Users\<username>\AppData\Local\WSL\`)

### Custom VHD Size

Set maximum VHD size (WSL VHDs grow dynamically up to this limit):

```powershell
# 512 GB max size
powershell -ExecutionPolicy Bypass -File $temp `
  -DistroName "Ubuntu-Dev" `
  -VhdSizeGB 512

# Large development environment
powershell -ExecutionPolicy Bypass -File $temp `
  -DistroName "BigData-Dev" `
  -VhdPath "D:\WSL\BigData" `
  -VhdSizeGB 1024
```

**Default size:** 256 GB

### Combined Example

```powershell
# Custom name, location, and size
powershell -ExecutionPolicy Bypass -File $temp `
  -DistroName "Enterprise-Dev" `
  -VhdPath "D:\WSL\Enterprise-Dev" `
  -VhdSizeGB 512
```

---

## Rebuild Mode

Destroys and recreates the instance (⚠️ **WARNING: deletes all data**):

```powershell
powershell -ExecutionPolicy Bypass -File $temp -Rebuild

# Or with custom name
powershell -ExecutionPolicy Bypass -File $temp -DistroName "MyDevEnv" -Rebuild
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

## VHD Management

Use the included `manage-vhd.ps1` script for common VHD operations:

### Check VHD Info & Disk Usage

```powershell
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Info
```

Shows:
- VHD file location and size
- Disk usage inside WSL
- Creation/modification dates

### Compact VHD (Reclaim Space)

WSL VHDs don't automatically shrink when you delete files. Compact to reclaim space:

```powershell
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Compact
```

This is useful after:
- Deleting large files or Docker images
- Running `apt autoremove` or clearing caches
- Uninstalling applications

### Resize VHD

Expand the maximum VHD size:

```powershell
# Increase to 512 GB
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Resize -NewSizeGB 512

# Increase to 1 TB
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Resize -NewSizeGB 1024
```

### Move VHD to Different Location

Move an existing instance to a different drive:

```powershell
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Move -NewPath "D:\WSL\Ubuntu-Dev"
```

**Manual method:**

```powershell
# 1. Export the distro
wsl --export Ubuntu-Dev D:\temp\ubuntu-dev.tar

# 2. Unregister the old one
wsl --unregister Ubuntu-Dev

# 3. Import to new location
wsl --import Ubuntu-Dev D:\WSL\Ubuntu-Dev D:\temp\ubuntu-dev.tar

# 4. Clean up
Remove-Item D:\temp\ubuntu-dev.tar
```

---

## Full Reset

Remove a WSL instance completely:

```powershell
# Default instance
wsl --unregister Ubuntu-Dev

# Or your custom instance
wsl --unregister MyDevEnv
```

List all WSL instances:

```powershell
wsl --list --verbose
```

---

## Quick Reference

### Common Commands

```powershell
# List all WSL instances
wsl --list --verbose

# Start a specific instance
wsl -d Ubuntu-Dev

# Shutdown all WSL instances
wsl --shutdown

# Set default instance
wsl --set-default Ubuntu-Dev

# Check WSL version
wsl --version

# Update WSL
wsl --update
```

### Example Workflows

**Create development environment on D: drive:**
```powershell
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 `
  -DistroName "Dev" `
  -VhdPath "D:\WSL\Dev" `
  -VhdSizeGB 512
```

**Create multiple project-specific environments:**
```powershell
# Frontend development
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 `
  -DistroName "Frontend-Dev" `
  -VhdPath "D:\WSL\Frontend"

# Backend development
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 `
  -DistroName "Backend-Dev" `
  -VhdPath "D:\WSL\Backend"

# Machine learning (large VHD)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 `
  -DistroName "ML-Dev" `
  -VhdPath "E:\WSL\ML" `
  -VhdSizeGB 1024
```

**Regular maintenance:**
```powershell
# Check disk usage
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Info

# Compact VHD monthly
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Compact

# Update WSL
wsl --update
wsl --shutdown
```
