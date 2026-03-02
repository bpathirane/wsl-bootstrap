param(
    [string]$DistroName = "Ubuntu-Dev",
    [string]$BaseDistro = "Ubuntu-24.04",  # Base distro to install/clone from (e.g., "Ubuntu-24.04", "Debian")
    [string]$GitHubUsername = "bpathirane",
    [string]$BootstrapRepoName = "wsl-bootstrap",
    [string]$VhdPath = "",  # Custom path for VHD (e.g., "D:\WSL\Ubuntu-Dev")
    [int]$VhdSizeGB = 256,  # Max VHD size in GB (default: 256GB)
    [bool]$DisableWindowsPath = $true,   # Disable Windows PATH injection (default: disabled)
    [bool]$DisableAutoMount = $true,     # Disable auto-mounting Windows drives (default: disabled)
    [switch]$Rebuild
)

$BootstrapRepo = "https://github.com/$GitHubUsername/$BootstrapRepoName.git"

# Determine VHD location
if ([string]::IsNullOrEmpty($VhdPath)) {
    $VhdPath = "$env:LOCALAPPDATA\WSL\$DistroName"
}

Write-Host "==============================================="
Write-Host "WSL Bootstrap"
Write-Host "Instance Name:        $DistroName"
Write-Host "Base Distro:          $BaseDistro"
Write-Host "VHD Location:         $VhdPath"
Write-Host "VHD Max Size:         $VhdSizeGB GB"
Write-Host "Disable Windows PATH: $DisableWindowsPath"
Write-Host "Disable Auto-Mount:   $DisableAutoMount"
Write-Host "Repo:                 $BootstrapRepo"
Write-Host "==============================================="
Write-Host ""

# Check if distro already exists
$existingDistros = wsl --list --quiet
$distroExists = $existingDistros -match [regex]::Escape($DistroName)

if ($distroExists -and -not $Rebuild) {
    Write-Host ""
    Write-Error "WSL instance '$DistroName' already exists!"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  1. Use a different name:"
    Write-Host "     powershell -ExecutionPolicy Bypass -File $PSCommandPath -DistroName 'MyCustomName'"
    Write-Host ""
    Write-Host "  2. Rebuild the existing instance (WARNING: destroys all data):"
    Write-Host "     powershell -ExecutionPolicy Bypass -File $PSCommandPath -DistroName '$DistroName' -Rebuild"
    Write-Host ""
    exit 1
}

if ($Rebuild) {
    Write-Host "Rebuild mode: removing existing distro '$DistroName'..."
    wsl --unregister $DistroName 2>$null
    Write-Host "Distro unregistered."
    Write-Host ""
}

Write-Host "Setting up WSL instance '$DistroName'..."
Write-Host ""

# Discover directly installable distros from the WSL online catalog
Write-Host "Checking available WSL distros..."
$onlineDistros = @()
$headerFound = $false
foreach ($line in (wsl --list --online 2>$null)) {
    if ($line -match '^NAME\s+') { $headerFound = $true; continue }
    if ($headerFound -and $line.Trim() -ne '') {
        $onlineDistros += ($line.Trim() -split '\s+')[0]
    }
}

$distroIsOnline = $onlineDistros -contains $DistroName

if ($distroIsOnline) {
    # DistroName is a known WSL distro — install it directly, no export/import needed
    Write-Host "Installing $DistroName from WSL catalog..."
    wsl --install -d $DistroName
} else {
    # Custom name — clone from BaseDistro via export/import
    if ($onlineDistros.Count -gt 0 -and -not ($onlineDistros -contains $BaseDistro)) {
        Write-Error "Base distro '$BaseDistro' is not available in the WSL online catalog."
        Write-Host "Available distros: $($onlineDistros -join ', ')"
        exit 1
    }

    Write-Host "Creating custom instance '$DistroName' from $BaseDistro base..."

    # Ensure base distro is installed locally
    $baseExists = (wsl --list --quiet) -match [regex]::Escape($BaseDistro)
    if (-not $baseExists) {
        Write-Host "Installing base $BaseDistro first..."
        wsl --install -d $BaseDistro
    }

    # Create instance directory
    if (-not (Test-Path $VhdPath)) {
        Write-Host "Creating VHD directory: $VhdPath"
        New-Item -ItemType Directory -Path $VhdPath -Force | Out-Null
    }

    # Export base distro and import under the custom name
    $tempTar = "$env:TEMP\wsl-export-$DistroName.tar"
    Write-Host "Exporting $BaseDistro..."
    wsl --export $BaseDistro $tempTar

    Write-Host "Importing as '$DistroName' to $VhdPath..."
    wsl --import $DistroName $VhdPath $tempTar

    Remove-Item $tempTar -Force

    # Carry over the default user from the base distro
    $baseUser = wsl -d $BaseDistro -- bash -c "echo `$USER" 2>$null
    if ($baseUser) {
        wsl -d $DistroName -- useradd -m -s /bin/bash $baseUser 2>$null
        wsl -d $DistroName -- usermod -aG sudo $baseUser 2>$null
    }
}

Write-Host ""

# Resize VHD if needed
$vhdFile = Join-Path $VhdPath "ext4.vhdx"
if (Test-Path $vhdFile) {
    Write-Host "Configuring VHD size to $VhdSizeGB GB..."

    # Create diskpart script
    $diskpartScript = @"
select vdisk file="$vhdFile"
expand vdisk maximum=$($VhdSizeGB * 1024)
exit
"@

    $diskpartFile = "$env:TEMP\diskpart-resize.txt"
    $diskpartScript | Out-File -FilePath $diskpartFile -Encoding ASCII

    # Run diskpart
    try {
        diskpart /s $diskpartFile | Out-Null
        Write-Host "VHD resized successfully."
    } catch {
        Write-Warning "Could not resize VHD. You may need to run as Administrator."
    } finally {
        Remove-Item $diskpartFile -Force -ErrorAction SilentlyContinue
    }

    # Resize the filesystem inside WSL
    Write-Host "Expanding filesystem inside WSL..."
    wsl -d $DistroName -- bash -c "sudo resize2fs /dev/sdb 2>/dev/null || true"
    Write-Host ""
}

Write-Host "If first install, you may need to create a user."
Write-Host "Starting WSL instance..."
wsl -d $DistroName
Write-Host ""
Read-Host "Press ENTER to continue with provisioning"

# Docker Desktop check
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerDesktopPath)) {
    Write-Warning "Docker Desktop not found. Install and enable WSL integration."
} else {
    Write-Host "Docker Desktop detected."
}

# Ensure git exists inside WSL
wsl -d $DistroName -- bash -c "sudo apt update && sudo apt install -y git"

# Clone repo
wsl -d $DistroName -- bash -c "
if [ ! -d ~/wsl-bootstrap ]; then
    git clone $BootstrapRepo ~/wsl-bootstrap
else
    echo 'Repo already exists.'
fi
"

# Run Linux bootstrap
$disablePathEnv = if ($DisableWindowsPath) { "true" } else { "false" }
$disableMountEnv = if ($DisableAutoMount) { "true" } else { "false" }

wsl -d $DistroName -- bash -c "
cd ~/wsl-bootstrap/linux &&
chmod +x *.sh &&
DISABLE_WINDOWS_PATH=$disablePathEnv DISABLE_AUTO_MOUNT=$disableMountEnv GITHUB_USER='$GitHubUsername' ./install.sh
"

Write-Host ""
Write-Host "==============================================="
Write-Host "Provisioning complete!"
Write-Host "==============================================="

if ($DisableWindowsPath -or $DisableAutoMount) {
    Write-Host ""
    Write-Host "IMPORTANT: WSL configuration was modified."
    Write-Host "Please restart WSL for changes to take effect:"
    Write-Host ""
    Write-Host "  wsl --shutdown"
    Write-Host "  wsl -d $DistroName"
    Write-Host ""
}
