function MicroWin-BootableUSB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$IsoPath
    )

    $TargetDisk = Get-Disk | Where-Object { $_.BusType -eq 'USB' -and $_.OperationalStatus -eq 'Online' } |
                    Sort-Object Number |
                    Out-GridView -Title "MicroWin: Select Target USB Drive" -OutputMode Single

    if (-not $TargetDisk) {
        Write-Warning "No USB drive selected. Operation cancelled."
        return
    }

    $msgTitle = "MicroWin USB Warning"
    $msgText  = "WARNING: ALL DATA ON DISK $($TargetDisk.Number) WILL BE DELETED!`n`nAre you sure you want to proceed?"
    $msgIcon  = [System.Windows.MessageBoxImage]::Warning
    $msgButton = [System.Windows.MessageBoxButton]::YesNo

    $Response = [System.Windows.MessageBox]::Show($msgText, $msgTitle, $msgButton, $msgIcon)
    if ($Response -ne "Yes") {
        Write-Warning "Operation cancelled by user."
        return
    }

    try {
        Write-Host "Cleaning Disk $($TargetDisk.Number)..." -ForegroundColor Yellow
        $TargetDisk | Clear-Disk -RemoveData -Confirm:$false
        $TargetDisk | Initialize-Disk -PartitionStyle GPT -PassThru -ErrorAction SilentlyContinue | Out-Null

        Write-Host "Creating NTFS Partition..." -ForegroundColor Yellow
        $Partition = New-Partition -DiskNumber $TargetDisk.Number -UseMaximumSize -AssignDriveLetter
        $USBLetter = "$($Partition.DriveLetter):"

        Format-Volume -DriveLetter $Partition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "MicroWin" -Confirm:$false

        Write-Host "Mounting ISO: $IsoPath" -ForegroundColor Cyan
        $Mount = Mount-DiskImage -ImagePath $IsoPath -PassThru
        $IsoLetter = ($Mount | Get-Volume).DriveLetter + ":"

        Write-Host "Copying files to $USBLetter (this may take a few minutes)..." -ForegroundColor Cyan
        Copy-Files "$($IsoLetter)" "$($USBLetter)" -Recurse -Force

        if (Test-Path "$IsoLetter\boot\bootsect.exe") {
            Write-Host "Applying Boot Code..." -ForegroundColor Green
            Set-Location "$IsoLetter\boot"
            ./bootsect.exe /nt60 "$USBLetter" /force /mbr
        }

        Dismount-DiskImage -ImagePath $IsoPath
        Write-Host "SUCCESS: MicroWin USB created on $USBLetter" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create USB: $($_.Exception.Message)"
    }
}
