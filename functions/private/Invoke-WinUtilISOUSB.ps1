function Invoke-WinUtilISORefreshUSBDrives {
    $combo    = $sync["WPFWin11ISOUSBDriveComboBox"]
    $removable = @(Get-Disk | Where-Object { $_.BusType -eq "USB" } | Sort-Object Number)

    $combo.Items.Clear()

    if ($removable.Count -eq 0) {
        $combo.Items.Add("No USB drives detected.")
        $combo.SelectedIndex = 0
        $sync["Win11ISOUSBDisks"] = @()
        Write-WinUtilISOLog "No USB drives detected."
        return
    }

    foreach ($disk in $removable) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        $combo.Items.Add("Disk $($disk.Number): $($disk.FriendlyName)  [$sizeGB GB] - $($disk.PartitionStyle)")
    }
    $combo.SelectedIndex = 0
    Write-WinUtilISOLog "Found $($removable.Count) USB drive(s)."
    $sync["Win11ISOUSBDisks"] = $removable
}

function Get-WinUtilFreeDriveLetter {
    <#
    .SYNOPSIS
        Returns the first unused drive letter between D and Z, or $null when there is none.
    #>

    $used = (Get-PSDrive -PSProvider FileSystem).Name
    foreach ($c in [char[]](68..90)) {
        if ($used -notcontains [string]$c) { return $c }
    }
    return $null
}

function Invoke-WinUtilISOWriteUSB {
    $contentsDir = $sync["Win11ISOContentsDir"]
    $usbDisks    = $sync["Win11ISOUSBDisks"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        Show-WinUtilMessage -Message "No modified ISO content found. Please complete Steps 1-3 first." -Title "Not Ready" -Button "OK" -Icon "Warning" | Out-Null
        return
    }

    $installEsd = Join-Path $contentsDir "sources\install.esd"
    if (Test-Path $installEsd) {
        $esdSizeBytes = (Get-Item $installEsd).Length
        if ($esdSizeBytes -ge 4GB) {
            $esdSizeMB = [math]::Ceiling($esdSizeBytes / 1MB)
            Show-WinUtilMessage -Message "This ISO uses an install.esd file that is $esdSizeMB MB. WinUtil's FAT32 USB format cannot store files larger than 4 GB.`n`nExport an ISO instead or use media with install.wim." -Title "USB Creation Not Supported" -Button "OK" -Icon "Warning" | Out-Null
            return
        }
    }

    $combo = $sync["WPFWin11ISOUSBDriveComboBox"]
    $selectedIndex = $combo.SelectedIndex
    $selectedItemText = [string]$combo.SelectedItem
    $usbDisks = @($usbDisks)

    $targetDisk = $null
    if ($selectedIndex -ge 0 -and $selectedIndex -lt $usbDisks.Count) {
        $targetDisk = $usbDisks[$selectedIndex]
    } elseif ($selectedItemText -match 'Disk\s+(\d+):') {
        $selectedDiskNum = [int]$matches[1]
        $targetDisk = $usbDisks | Where-Object { $_.Number -eq $selectedDiskNum } | Select-Object -First 1
    }

    if (-not $targetDisk) {
        Show-WinUtilMessage -Message "Please select a USB drive from the dropdown." -Title "No Drive Selected" -Button "OK" -Icon "Warning" | Out-Null
        return
    }

    $diskNum = $targetDisk.Number
    $sizeGB  = [math]::Round($targetDisk.Size / 1GB, 1)

    $confirm = Show-WinUtilMessage -Message "ALL data on Disk $diskNum ($($targetDisk.FriendlyName), $sizeGB GB) will be PERMANENTLY ERASED.`n`nAre you sure you want to continue?" -Title "Confirm USB Erase" -Button "YesNo" -Icon "Warning"
    if ($confirm -ne "Yes") {
        Write-WinUtilISOLog "USB write cancelled by user."
        return
    }

    Start-WinUtilJob -Name "USB write" -Description "Writing USB drive" -Parameters @{
        DiskNumber  = $diskNum
        ContentsDir = $contentsDir
    } -ScriptBlock {
        param($DiskNumber, $contentsDir)

        Invoke-WPFUIThread -ScriptBlock { $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $false }

        try {
            Write-WinUtilISOLog "Starting USB write to Disk $DiskNumber..."
            Step-WinUtilJob -Status "Formatting USB drive..." -Percent 10

            # Phase 1: Clean disk via diskpart (retry once if the drive is not yet ready)
            $dpFile1 = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
            "select disk $DiskNumber`nclean`nexit" | Set-Content -Path $dpFile1 -Encoding ASCII
            Write-WinUtilISOLog "Running diskpart clean on Disk $DiskNumber..."
            $dpCleanOut = diskpart /s $dpFile1
            $dpCleanOut | Where-Object { $_ -match '\S' } | ForEach-Object { Write-WinUtilISOLog "  diskpart: $_" }
            Remove-Item $dpFile1 -Force

            if (($dpCleanOut -join ' ') -match 'device is not ready') {
                Write-WinUtilISOLog "Disk $DiskNumber was not ready; waiting 5 seconds and retrying clean..."
                Start-Sleep -Seconds 5
                Update-Disk -Number $DiskNumber
                $dpFile1b = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
                "select disk $DiskNumber`nclean`nexit" | Set-Content -Path $dpFile1b -Encoding ASCII
                diskpart /s $dpFile1b | Where-Object { $_ -match '\S' } | ForEach-Object { Write-WinUtilISOLog "  diskpart: $_" }
                Remove-Item $dpFile1b -Force
            }

            # Phase 2: Initialize as GPT
            Start-Sleep -Seconds 2
            Update-Disk -Number $DiskNumber
            $diskObj = Get-Disk -Number $DiskNumber
            if ($diskObj.PartitionStyle -eq 'RAW') {
                Initialize-Disk -Number $DiskNumber -PartitionStyle GPT
                Write-WinUtilISOLog "Disk $DiskNumber initialized as GPT."
            } else {
                Set-Disk -Number $DiskNumber -PartitionStyle GPT
                Write-WinUtilISOLog "Disk $DiskNumber converted to GPT (was $($diskObj.PartitionStyle))."
            }

            # Phase 3: Create FAT32 partition via diskpart, then format with Format-Volume
            # (diskpart's 'format' command can fail with "no volume selected" on fresh/never-formatted drives)
            $volLabel = "W11-" + (Get-Date).ToString('yyMMdd')
            $dpFile2  = Join-Path $env:TEMP "winutil_diskpart2_$(Get-Random).txt"
            $maxFat32PartitionMB = 32768
            $diskSizeMB = [int][Math]::Floor((Get-Disk -Number $DiskNumber).Size / 1MB)
            $createPartitionCommand = "create partition primary"
            if ($diskSizeMB -gt $maxFat32PartitionMB) {
                $createPartitionCommand = "create partition primary size=$maxFat32PartitionMB"
                Write-WinUtilISOLog "Disk $DiskNumber is $diskSizeMB MB; creating FAT32 partition capped at $maxFat32PartitionMB MB (32 GB)."
            }

            @(
                "select disk $DiskNumber"
                $createPartitionCommand
                "exit"
            ) | Set-Content -Path $dpFile2 -Encoding ASCII
            Write-WinUtilISOLog "Creating partitions on Disk $DiskNumber..."
            diskpart /s $dpFile2 | Where-Object { $_ -match '\S' } | ForEach-Object { Write-WinUtilISOLog "  diskpart: $_" }
            Remove-Item $dpFile2 -Force

            Step-WinUtilJob -Status "Formatting USB partition..." -Percent 25
            Start-Sleep -Seconds 3
            Update-Disk -Number $DiskNumber

            $partitions = Get-Partition -DiskNumber $DiskNumber
            Write-WinUtilISOLog "Partitions on Disk $DiskNumber after creation: $($partitions.Count)"
            foreach ($p in $partitions) {
                Write-WinUtilISOLog "  Partition $($p.PartitionNumber)  Type=$($p.Type)  Letter=$($p.DriveLetter)  Size=$([math]::Round($p.Size/1MB))MB"
            }

            $winpePart = $partitions | Where-Object { $_.Type -eq "Basic" } | Select-Object -Last 1
            if (-not $winpePart) {
                throw "Could not find the Basic partition on Disk $DiskNumber after creation."
            }

            # Format using Format-Volume (reliable on fresh drives; diskpart format fails
            # with 'no volume selected' when the partition has never been formatted before)
            Write-WinUtilISOLog "Formatting Partition $($winpePart.PartitionNumber) as FAT32 (label: $volLabel)..."
            Get-Partition -DiskNumber $DiskNumber -PartitionNumber $winpePart.PartitionNumber |
                Format-Volume -FileSystem FAT32 -NewFileSystemLabel $volLabel -Force -Confirm:$false
            Write-WinUtilISOLog "Partition $($winpePart.PartitionNumber) formatted as FAT32."

            Step-WinUtilJob -Status "Assigning drive letters..." -Percent 30
            Start-Sleep -Seconds 2
            Update-Disk -Number $DiskNumber

            try { Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $winpePart.PartitionNumber -AccessPath "$($winpePart.DriveLetter):" } catch { Write-WinUtilISOLog -Level "WARN" -Message "Could not remove existing partition access path: $_" }
            $usbLetter = Get-WinUtilFreeDriveLetter
            if (-not $usbLetter) { throw "No free drive letters (D-Z) available to assign to the USB data partition." }
            Set-Partition -DiskNumber $DiskNumber -PartitionNumber $winpePart.PartitionNumber -NewDriveLetter $usbLetter
            Write-WinUtilISOLog "Assigned drive letter $usbLetter to WINPE partition (Partition $($winpePart.PartitionNumber))."
            Start-Sleep -Seconds 2

            $usbDrive = "${usbLetter}:"
            $retries = 0
            while (-not (Test-Path $usbDrive) -and $retries -lt 6) {
                $retries++
                Write-WinUtilISOLog "Waiting for $usbDrive to become accessible (attempt $retries/6)..."
                Start-Sleep -Seconds 2
            }
            if (-not (Test-Path $usbDrive)) { throw "Drive $usbDrive is not accessible after letter assignment." }
            Write-WinUtilISOLog "USB data partition: $usbDrive"

            $contentSizeBytes = (Get-ChildItem -LiteralPath $contentsDir -File -Recurse -Force | Measure-Object -Property Length -Sum).Sum
            if (-not $contentSizeBytes) { $contentSizeBytes = 0 }
            $usbVolume = Get-Volume -DriveLetter $usbLetter
            $partitionCapacityBytes = [int64]$usbVolume.Size
            $partitionFreeBytes = [int64]$usbVolume.SizeRemaining

            $contentSizeGB = [math]::Round($contentSizeBytes / 1GB, 2)
            $partitionCapacityGB = [math]::Round($partitionCapacityBytes / 1GB, 2)
            $partitionFreeGB = [math]::Round($partitionFreeBytes / 1GB, 2)

            Write-WinUtilISOLog "Source content size: $contentSizeGB GB. USB partition capacity: $partitionCapacityGB GB, free: $partitionFreeGB GB."

            if ($contentSizeBytes -gt $partitionCapacityBytes) {
                throw "ISO content ($contentSizeGB GB) is larger than the USB partition capacity ($partitionCapacityGB GB). Use a larger USB drive or reduce image size."
            }

            if ($contentSizeBytes -gt $partitionFreeBytes) {
                throw "Insufficient free space on USB partition. Required: $contentSizeGB GB, available: $partitionFreeGB GB."
            }

            Step-WinUtilJob -Status "Copying Windows 11 files to USB..." -Percent 45

            # Copy files; split install.wim if > 4 GB (FAT32 limit)
            $installWim = Join-Path $contentsDir "sources\install.wim"
            if (Test-Path $installWim) {
                $wimSizeMB = [math]::Round((Get-Item $installWim).Length / 1MB)
                if ($wimSizeMB -gt 3800) {
                    Write-WinUtilISOLog "install.wim is $wimSizeMB MB - splitting for FAT32 compatibility... This will take several minutes."
                    Set-ItemProperty -LiteralPath $installWim -Name IsReadOnly -Value $false
                    $splitDest = Join-Path $usbDrive "sources\install.swm"
                    New-Item -ItemType Directory -Path (Split-Path $splitDest) -Force | Out-Null
                    Split-WindowsImage -ImagePath $installWim -SplitImagePath $splitDest -FileSize 3800 -CheckIntegrity
                    Write-WinUtilISOLog "install.wim split complete."
                    Write-WinUtilISOLog "Copying remaining files to USB..."
                    Invoke-WinUtilRobocopy -Source $contentsDir -Destination $usbDrive -Arguments @("/E","/XF","install.wim","/NFL","/NDL","/NJH","/NJS")
                } else {
                    Invoke-WinUtilRobocopy -Source $contentsDir -Destination $usbDrive -Arguments @("/E","/NFL","/NDL","/NJH","/NJS")
                }
            } else {
                Invoke-WinUtilRobocopy -Source $contentsDir -Destination $usbDrive -Arguments @("/E","/NFL","/NDL","/NJH","/NJS")
            }

            Step-WinUtilJob -Status "Finalising USB drive..." -Percent 90
            Write-WinUtilISOLog "Files copied to USB."
            Step-WinUtilJob -Status "USB write complete" -Percent 100
            Write-WinUtilISOLog "USB drive is ready for use."

            Show-WinUtilMessage -Message "USB drive created successfully!`n`nYou can now boot from this drive to install Windows 11." -Title "USB Ready" -Button "OK" -Icon "Info" | Out-Null
        } catch {
            Write-WinUtilISOLog -Level "ERROR" -Message "USB write failed: $_"
            $_.Exception.Data["WinUtilErrorReported"] = $true
            Show-WinUtilMessage -Message "USB write failed:`n`n$_" -Title "USB Write Error" -Button "OK" -Icon "Error" | Out-Null
            throw
        } finally {
            Invoke-WPFUIThread -ScriptBlock { $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $true }
        }
    }
}
