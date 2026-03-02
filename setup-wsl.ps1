param(
    [string]$DistroName = "Ubuntu-Dev",
    [string]$BaseDistro = "Ubuntu-24.04",  # Base distro to install/clone from (e.g., "Ubuntu-24.04", "Debian")
    [string]$WslUsername = "buddhi",        # Default Linux user to create inside the instance
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
Write-Host "WSL Username:         $WslUsername"
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

    # Prompt for the new user's password with confirmation
    do {
        $securePass = Read-Host "Enter password for '$WslUsername'" -AsSecureString
        $secureConfirm = Read-Host "Confirm password for '$WslUsername'" -AsSecureString
        $plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
        $plainConfirm = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureConfirm))
        if ($plainPass -ne $plainConfirm) {
            Write-Warning "Passwords do not match. Please try again."
        }
    } while ($plainPass -ne $plainConfirm)

    # Create the default user and set as default in wsl.conf
    Write-Host "Creating user '$WslUsername'..."
    wsl -d $DistroName -u root -- bash -c "
        id -u $WslUsername &>/dev/null || useradd -m -s /bin/bash $WslUsername
        usermod -aG sudo $WslUsername
        echo '$WslUsername ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$WslUsername
        printf '[user]\ndefault = $WslUsername\n' >> /etc/wsl.conf
    "

    # Set password via chpasswd — pipe through tr to strip Windows \r before chpasswd reads it
    "${WslUsername}:${plainPass}" | wsl -d $DistroName -u root -- bash -c "tr -d '\r' | chpasswd"
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
    wsl -d $DistroName -u root -- bash -c "resize2fs /dev/sdb 2>/dev/null || true"
    Write-Host ""
}

# Docker Desktop check
$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerDesktopPath)) {
    Write-Warning "Docker Desktop not found. Install and enable WSL integration."
} else {
    Write-Host "Docker Desktop detected."
}

# Ensure git exists inside WSL (run as root, apt needs it)
wsl -d $DistroName -u root -- bash -c "apt-get update -q && apt-get install -y -q git"

# Clone repo and run bootstrap as the WSL user
wsl -d $DistroName -u $WslUsername -- bash -c "
mkdir -p ~/source/github_personal
if [ ! -d ~/source/github_personal/wsl-bootstrap ]; then
    git clone $BootstrapRepo ~/source/github_personal/wsl-bootstrap
else
    echo 'Repo already exists.'
fi
"

# Run Linux bootstrap as the WSL user
$disablePathEnv = if ($DisableWindowsPath) { "true" } else { "false" }
$disableMountEnv = if ($DisableAutoMount) { "true" } else { "false" }

wsl -d $DistroName -u $WslUsername -- bash -c "
cd ~/source/github_personal/wsl-bootstrap/linux &&
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
