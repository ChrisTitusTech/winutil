function Invoke-WinUtilISOUSB ($IsoPath, $UsbDriveLetter) {
    if (-not $UsbDriveLetter) {
        Write-Host "No USB drive selected"
        return
    }

    Write-Host "Mounting ISO..."
    Mount-DiskImage -ImagePath $IsoPath
    $Drive = (Get-CimInstance Win32_CDROMDrive).Drive

    $result = [System.Windows.Forms.MessageBox]::Show(
        "This will ERASE all data on $UsbDriveLetter. Continue?",
        "USB Format Confirmation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host "USB format cancelled"
        return
    }

    Write-Host "Formatting USB..."
    Format-Volume -DriveLetter $UsbDriveLetter.TrimEnd(":") -FileSystem NTFS -Force

    Write-Host "Copying files to USB..."
    Copy-Item -Path "$isoDrive\*" -Destination "$UsbDriveLetter\" -Recurse -Force

    Dismount-DiskImage -ImagePath $IsoPath

    Write-Host "USB creation complete" -ForegroundColor Green
}
