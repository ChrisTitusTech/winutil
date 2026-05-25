function Invoke-WinUtilUSB ($IsoPath, $UsbDriveLetter) {
    if (-not $UsbDriveLetter) {
        Write-Host "No USB drive selected"
        return
    }

    Write-Host "Mounting ISO..."

    $mounted = Mount-DiskImage -ImagePath $IsoPath
    $isoDrive = (Get-CimInstance Win32_CDROMDrive | Select-Object -First 1).Drive

    Write-Host "Formatting USB..."
    Format-Volume -DriveLetter $UsbDriveLetter.TrimEnd(":") -FileSystem NTFS -Force

    Write-Host "Copying files to USB..."
    Copy-Item -Path "$isoDrive\*" -Destination "$UsbDriveLetter\" -Recurse -Force

    Dismount-DiskImage -ImagePath $IsoPath

    Write-Host "USB creation complete" -ForegroundColor Green
}
