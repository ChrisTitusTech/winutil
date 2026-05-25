function Invoke-WinUtilISODrivers {

    param(
        [string]$SourcePath,
        [int]$Index
    )

    $exportPath = "$env:TEMP\Win11Drivers"

    if (Test-Path $exportPath) {
        Remove-Item $exportPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $exportPath -Force | Out-Null

    Write-Host "Exporting system drivers..."
    Export-WindowsDriver -Online -Destination $exportPath

    $wimPath = "$SourcePath\sources\install.wim"

    if (-not (Test-Path $wimPath)) {
        Write-Host "install.wim not found"
        return
    }

    $mountDir = "$env:TEMP\wim_$Index"

    if (Test-Path $mountDir) {
        Remove-Item $mountDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $mountDir -Force | Out-Null

    Write-Host "Mounting WIM index $Index..."

    Mount-WindowsImage -ImagePath $wimPath -Index $Index -Path $mountDir

    Write-Host "Injecting drivers..."

    Add-WindowsDriver -Path $mountDir -Driver $exportPath -Recurse

    Write-Host "Committing changes..."

    Dismount-WindowsImage -Path $mountDir -Save

    Remove-Item $mountDir -Recurse -Force

    Write-Host "Driver injection complete"
}
