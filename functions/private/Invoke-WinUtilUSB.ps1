function Invoke-WinUtilUSB ($IsoPath, $UsbDriveLetter) {
    if (-not $UsbDriveLetter) {
        Write-Host "No USB drive selected"
        return
    }

    Write-Host "Mounting ISO..."
    Mount-DiskImage -ImagePath $IsoPath
    $Drive = (Get-CimInstance Win32_CDROMDrive).Drive

    Write-Host "Formatting USB..."
    Format-Volume -DriveLetter $UsbDriveLetter.TrimEnd(":") -FileSystem NTFS -Force

    Write-Host "Copying files to USB..."
    Copy-Item -Path "$isoDrive\*" -Destination "$UsbDriveLetter\" -Recurse -Force

    Dismount-DiskImage -ImagePath $IsoPath

    Write-Host "USB creation complete" -ForegroundColor Green
}
