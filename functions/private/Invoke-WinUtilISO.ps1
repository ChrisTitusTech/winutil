Function Invoke-WinUtilISO {
    Write-Host "Please choose you're iso file"

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.Title = "Select Windows ISO"
    $dialog.ShowDialog()
    
    if (-not $dialog.FileName) { return }

    Write-Host "Mounting iso file..."

    Mount-DiskImage -ImagePath $dialog.FileName
    $Drive = ($Drive = Get-CimInstance Win32_CDROMDrive).Drive
    
    Write-Host "Copying files..."
    
    New-Item -Path "Sources" -ItemType Directory
    Copy-Item -Path "$Drive\*" -Destination "Sources" -Recurse -Force

    Write-Host "Downloading oscdimg.exe and injecting autounattend.xml..."

    Invoke-WebRequest -Uri https://github.com/GabiNun2/winutil/raw/refactor-win11creator/tools/autounattend.xml -OutFile "Sources\autounattend.xml"
    Invoke-WebRequest -Uri https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe -OutFile "oscdimg.exe"
    
    Write-Host "Packing files into a iso file..."
    
    $path = Split-Path -Path $dialog.FileName
    .\oscdimg.exe -u2 -b"Sources\efi\microsoft\boot\efisys.bin" "Sources" "$path\Win11Creator.iso"

    Write-Host "Cleaning up..."

    Remove-Item -Path "Sources", "oscdimg.exe" -Recurse -Force
    Dismount-DiskImage -ImagePath $dialog.FileName

    return "$path\Win11Creator.iso"
    Write-Host "Done! iso file located at $path\Win11Creator.iso" -ForegroundColor Green
}
