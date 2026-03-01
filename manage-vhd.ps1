param(
    [Parameter(Mandatory=$true)]
    [string]$DistroName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Info", "Compact", "Resize", "Move")]
    [string]$Action,

    [int]$NewSizeGB = 0,
    [string]$NewPath = ""
)

$ErrorActionPreference = "Stop"

# Find VHD location
function Get-VhdPath {
    param([string]$distro)

    # Check default location
    $defaultPath = "$env:LOCALAPPDATA\WSL\$distro\ext4.vhdx"
    if (Test-Path $defaultPath) {
        return $defaultPath
    }

    # Search common locations
    $locations = @(
        "C:\WSL\$distro\ext4.vhdx",
        "D:\WSL\$distro\ext4.vhdx",
        "$env:USERPROFILE\WSL\$distro\ext4.vhdx"
    )

    foreach ($loc in $locations) {
        if (Test-Path $loc) {
            return $loc
        }
    }

    Write-Error "Could not find VHD for distro '$distro'"
    exit 1
}

$vhdPath = Get-VhdPath -distro $DistroName
Write-Host "Found VHD: $vhdPath"
Write-Host ""

switch ($Action) {
    "Info" {
        Write-Host "=== VHD Information ==="
        $vhd = Get-Item $vhdPath
        Write-Host "Location:    $($vhd.FullName)"
        Write-Host "Size:        $([math]::Round($vhd.Length / 1GB, 2)) GB"
        Write-Host "Created:     $($vhd.CreationTime)"
        Write-Host "Modified:    $($vhd.LastWriteTime)"
        Write-Host ""

        Write-Host "=== WSL Disk Usage ==="
        wsl -d $DistroName -- df -h /
    }

    "Compact" {
        Write-Host "Compacting VHD (reclaiming unused space)..."
        Write-Host ""

        # Get size before
        $sizeBefore = (Get-Item $vhdPath).Length

        # Shutdown WSL
        Write-Host "Shutting down WSL..."
        wsl --shutdown
        Start-Sleep -Seconds 2

        # Compact using diskpart
        $diskpartScript = @"
select vdisk file="$vhdPath"
compact vdisk
exit
"@

        $scriptFile = "$env:TEMP\compact-vhd.txt"
        $diskpartScript | Out-File -FilePath $scriptFile -Encoding ASCII

        Write-Host "Running diskpart..."
        diskpart /s $scriptFile

        Remove-Item $scriptFile -Force

        # Get size after
        $sizeAfter = (Get-Item $vhdPath).Length
        $saved = [math]::Round(($sizeBefore - $sizeAfter) / 1GB, 2)

        Write-Host ""
        Write-Host "Compact complete!"
        Write-Host "Before: $([math]::Round($sizeBefore / 1GB, 2)) GB"
        Write-Host "After:  $([math]::Round($sizeAfter / 1GB, 2)) GB"
        Write-Host "Saved:  $saved GB"
    }

    "Resize" {
        if ($NewSizeGB -eq 0) {
            Write-Error "Please specify -NewSizeGB parameter"
            exit 1
        }

        Write-Host "Resizing VHD to $NewSizeGB GB..."
        Write-Host ""

        # Shutdown WSL
        Write-Host "Shutting down WSL..."
        wsl --shutdown
        Start-Sleep -Seconds 2

        # Resize using diskpart
        $diskpartScript = @"
select vdisk file="$vhdPath"
expand vdisk maximum=$($NewSizeGB * 1024)
exit
"@

        $scriptFile = "$env:TEMP\resize-vhd.txt"
        $diskpartScript | Out-File -FilePath $scriptFile -Encoding ASCII

        Write-Host "Running diskpart..."
        diskpart /s $scriptFile

        Remove-Item $scriptFile -Force

        # Resize filesystem
        Write-Host "Expanding filesystem..."
        wsl -d $DistroName -- sudo resize2fs /dev/sdb 2>$null

        Write-Host ""
        Write-Host "Resize complete! New max size: $NewSizeGB GB"
        Write-Host ""
        wsl -d $DistroName -- df -h /
    }

    "Move" {
        if ([string]::IsNullOrEmpty($NewPath)) {
            Write-Error "Please specify -NewPath parameter"
            exit 1
        }

        Write-Host "Moving VHD from:"
        Write-Host "  $vhdPath"
        Write-Host "To:"
        Write-Host "  $NewPath"
        Write-Host ""

        # Create temp export
        $tempTar = "$env:TEMP\wsl-move-$DistroName.tar"

        Write-Host "Exporting distro..."
        wsl --export $DistroName $tempTar

        Write-Host "Unregistering old instance..."
        wsl --unregister $DistroName

        # Create new directory
        if (-not (Test-Path $NewPath)) {
            New-Item -ItemType Directory -Path $NewPath -Force | Out-Null
        }

        Write-Host "Importing to new location..."
        wsl --import $DistroName $NewPath $tempTar

        Write-Host "Cleaning up..."
        Remove-Item $tempTar -Force

        Write-Host ""
        Write-Host "Move complete!"
        Write-Host "New VHD location: $NewPath\ext4.vhdx"
    }
}

Write-Host ""
Write-Host "Done."
