param(
    [string]$DistroName = "Ubuntu",
    [string]$GitHubUsername = "bpathirane",
    [string]$BootstrapRepoName = "wsl-bootstrap",
    [switch]$Rebuild
)

$BootstrapRepo = "https://github.com/$GitHubUsername/$BootstrapRepoName.git"

Write-Host "WSL Bootstrap"
Write-Host "Repo: $BootstrapRepo"
Write-Host ""

if ($Rebuild) {
    Write-Host "Rebuild mode: removing existing distro..."
    wsl --unregister $DistroName 2>$null
}

Write-Host "Ensuring WSL + $DistroName installed..."
wsl --install -d $DistroName 2>$null

Write-Host ""
Write-Host "If first install, complete Ubuntu user setup."
Read-Host "Press ENTER to continue"

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
