Function Invoke-WinUtilISO {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.Title = "Select Windows ISO"
    $dialog.ShowDialog() | Out-Null
    
    if (-not $dialog.FileName) { return }
    
    Mount-DiskImage -ImagePath $dialog.FileName | Out-Null
    $Drive = ($Drive = Get-CimInstance Win32_CDROMDrive).Drive
    
    Write-Host "Copying files..."
    
    New-Item -Path "Sources" -ItemType Directory | Out-Null
    Copy-Item -Path "$Drive\*" -Destination "Sources" -Recurse -Force
    
    Invoke-WebRequest -Uri https://github.com/GabiNun2/test/raw/main/autounattend.xml -OutFile "Sources\autounattend.xml"
    Invoke-WebRequest -Uri https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe -OutFile "oscdimg.exe"
    
    Write-Host "Packing files into a iso file..."
    
    $path = Split-Path -Path $dialog.FileName
    .\oscdimg.exe -u2 -b"Sources\efi\microsoft\boot\efisys.bin" "Sources" "$path\Win11Creator.iso" | Out-Null
    
    Remove-Item -Path "Sources", "oscdimg.exe" -Recurse -Force
    Dismount-DiskImage -ImagePath $dialog.FileName | Out-Null
    
    Write-Host "Done! iso file located at $path\Win11Creator.iso"
}
