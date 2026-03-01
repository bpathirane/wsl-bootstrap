param(
    [string]$DistroName = "Ubuntu-Dev",
    [string]$GitHubUsername = "bpathirane",
    [string]$BootstrapRepoName = "wsl-bootstrap",
    [string]$VhdPath = "",  # Custom path for VHD (e.g., "D:\WSL\Ubuntu-Dev")
    [int]$VhdSizeGB = 256,  # Max VHD size in GB (default: 256GB)
    [switch]$Rebuild
)

$BootstrapRepo = "https://github.com/$GitHubUsername/$BootstrapRepoName.git"

# Determine VHD location
if ([string]::IsNullOrEmpty($VhdPath)) {
    $VhdPath = "$env:LOCALAPPDATA\WSL\$DistroName"
}

Write-Host "==============================================="
Write-Host "WSL Bootstrap"
Write-Host "Instance Name: $DistroName"
Write-Host "VHD Location:  $VhdPath"
Write-Host "VHD Max Size:  $VhdSizeGB GB"
Write-Host "Repo:          $BootstrapRepo"
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

# Check if we need to create a custom-named instance
$standardDistros = @("Ubuntu", "Debian", "Ubuntu-24.04", "Ubuntu-22.04", "Ubuntu-20.04")
$isStandardName = $standardDistros -contains $DistroName

if ($isStandardName) {
    # Standard distro - use wsl --install
    Write-Host "Installing standard distro: $DistroName"
    wsl --install -d $DistroName 2>$null
} else {
    # Custom name - need to import from a base distro
    Write-Host "Creating custom instance from Ubuntu base..."

    # Ensure base Ubuntu is available
    $baseDistro = "Ubuntu"
    $baseExists = (wsl --list --quiet) -match [regex]::Escape($baseDistro)

    if (-not $baseExists) {
        Write-Host "Installing base Ubuntu distro first..."
        wsl --install -d Ubuntu
    }

    # Create instance directory
    if (-not (Test-Path $VhdPath)) {
        Write-Host "Creating VHD directory: $VhdPath"
        New-Item -ItemType Directory -Path $VhdPath -Force | Out-Null
    }

    # Export and import to create named instance
    $tempTar = "$env:TEMP\wsl-export-$DistroName.tar"
    Write-Host "Exporting base Ubuntu..."
    wsl --export $baseDistro $tempTar

    Write-Host "Importing as '$DistroName' to $VhdPath..."
    wsl --import $DistroName $VhdPath $tempTar

    Remove-Item $tempTar -Force

    # Set default user (if base Ubuntu had one)
    $baseUser = wsl -d $baseDistro -- bash -c "echo `$USER" 2>$null
    if ($baseUser) {
        wsl -d $DistroName -- useradd -m -s /bin/bash $baseUser 2>$null
        wsl -d $DistroName -- usermod -aG sudo $baseUser 2>$null
        # Set default user for this distro
        ubuntu config --default-user $baseUser 2>$null
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
wsl -d $DistroName -- bash -c "
cd ~/wsl-bootstrap/linux &&
chmod +x *.sh &&
./install.sh
"

Write-Host ""
Write-Host "Provisioning complete."
