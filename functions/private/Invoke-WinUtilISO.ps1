Function Invoke-WinUtilISO ($IsoPath) {
    Write-Host "Mounting iso file..."

    Mount-DiskImage -ImagePath $IsoPath
    $Drive = (Get-CimInstance Win32_CDROMDrive).Drive
    
    Write-Host "Copying files..."
    
    New-Item -Path "Sources" -ItemType Directory
    Copy-Item -Path "$Drive\*" -Destination "Sources" -Recurse -Force

    Write-Host "Downloading oscdimg.exe and injecting autounattend.xml..."

    Invoke-WebRequest -Uri https://github.com/GabiNun2/winutil/raw/refactor-win11creator/tools/autounattend.xml -OutFile "Sources\autounattend.xml"
    Invoke-WebRequest -Uri https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe -OutFile "oscdimg.exe"
    
    $path = Split-Path -Path $IsoPath

    Write-Host "Packing files into $path\Win11Creator.iso..."
    .\oscdimg.exe -u2 -b"Sources\efi\microsoft\boot\efisys.bin" "Sources" "$path\Win11Creator.iso"

    Write-Host "Cleaning up..."

    Remove-Item -Path "Sources", "oscdimg.exe" -Recurse -Force
    Dismount-DiskImage -ImagePath $dialog.FileName

    Write-Host "Done! iso file located at $path\Win11Creator.iso" -ForegroundColor Green
    return "$path\Win11Creator.iso"
}
