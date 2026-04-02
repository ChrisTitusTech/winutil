function Invoke-WinUtilISORefreshUSBDrives {
    $combo    = $sync["WPFWin11ISOUSBDriveComboBox"]
    $removable = @(Get-Disk | Where-Object { $_.BusType -eq "USB" } | Sort-Object Number)

    $combo.Items.Clear()

    if ($removable.Count -eq 0) {
        $combo.Items.Add("No USB drives detected")
        $combo.SelectedIndex = 0
        $sync["Win11ISOUSBDisks"] = @()
        Write-Win11ISOLog "No USB drives detected."
        return
    }

    foreach ($disk in $removable) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        $combo.Items.Add("Disk $($disk.Number): $($disk.FriendlyName)  [$sizeGB GB] - $($disk.PartitionStyle)")
    }
    $combo.SelectedIndex = 0
    Write-Win11ISOLog "Found $($removable.Count) USB drive(s)."
    $sync["Win11ISOUSBDisks"] = $removable
}

function Invoke-WinUtilISOWriteUSB {
    $contentsDir = $sync["Win11ISOContentsDir"]
    $usbDisks    = $sync["Win11ISOUSBDisks"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show("No modified ISO content found.  Please complete Steps 1-3 first.", "Not Ready", "OK", "Warning")
        return
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
        [System.Windows.MessageBox]::Show("Please select a USB drive from the dropdown.", "No Drive Selected", "OK", "Warning")
        return
    }

    $diskNum    = $targetDisk.Number
    $sizeGB     = [math]::Round($targetDisk.Size / 1GB, 1)

    $confirm = [System.Windows.MessageBox]::Show(
        "ALL data on Disk $diskNum ($($targetDisk.FriendlyName), $sizeGB GB) will be PERMANENTLY ERASED.`n`nAre you sure you want to continue?",
        "Confirm USB Erase", "YesNo", "Warning")

    if ($confirm -ne "Yes") {
        Write-Win11ISOLog "USB write cancelled by user."
        return
    }

    $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $false
    Write-Win11ISOLog "Starting USB write to Disk $diskNum..."

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync",        $sync)
    $runspace.SessionStateProxy.SetVariable("diskNum",     $diskNum)
    $runspace.SessionStateProxy.SetVariable("contentsDir", $contentsDir)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({

        function Log($msg) {
            $ts = (Get-Date).ToString("HH:mm:ss")
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text += "`n[$ts] $msg"
                $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value            = [Math]::Max($pct, 5)
            })
        }

        function Get-FreeDriveLetter {
            $used = (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue).Name
            foreach ($c in [char[]](68..90)) {
                if ($used -notcontains [string]$c) { return $c }
            }
            return $null
        }

        try {
            SetProgress "Formatting USB drive..." 10

            # Phase 1: Clean disk via diskpart (retry once if the drive is not yet ready)
            $dpFile1 = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
            "select disk $diskNum`nclean`nexit" | Set-Content -Path $dpFile1 -Encoding ASCII
            Log "Running diskpart clean on Disk $diskNum..."
            $dpCleanOut = diskpart /s $dpFile1 2>&1
            $dpCleanOut | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }
            Remove-Item $dpFile1 -Force -ErrorAction SilentlyContinue

            if (($dpCleanOut -join ' ') -match 'device is not ready') {
                Log "Disk $diskNum was not ready; waiting 5 seconds and retrying clean..."
                Start-Sleep -Seconds 5
                Update-Disk -Number $diskNum -ErrorAction SilentlyContinue
                $dpFile1b = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
                "select disk $diskNum`nclean`nexit" | Set-Content -Path $dpFile1b -Encoding ASCII
                diskpart /s $dpFile1b 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }
                Remove-Item $dpFile1b -Force -ErrorAction SilentlyContinue
            }

            # Phase 2: Initialize as GPT
            Start-Sleep -Seconds 2
            Update-Disk -Number $diskNum -ErrorAction SilentlyContinue
            $diskObj = Get-Disk -Number $diskNum -ErrorAction Stop
            if ($diskObj.PartitionStyle -eq 'RAW') {
                Initialize-Disk -Number $diskNum -PartitionStyle GPT -ErrorAction Stop
                Log "Disk $diskNum initialized as GPT."
            } else {
                Set-Disk -Number $diskNum -PartitionStyle GPT -ErrorAction Stop
                Log "Disk $diskNum converted to GPT (was $($diskObj.PartitionStyle))."
            }

            # Phase 3: Create FAT32 partition via diskpart, then format with Format-Volume
            # (diskpart's 'format' command can fail with "no volume selected" on fresh/never-formatted drives)
            $volLabel = "W11-" + (Get-Date).ToString('yyMMdd')
            $dpFile2  = Join-Path $env:TEMP "winutil_diskpart2_$(Get-Random).txt"
            $maxFat32PartitionMB = 32768
            $diskSizeMB = [int][Math]::Floor((Get-Disk -Number $diskNum -ErrorAction Stop).Size / 1MB)
            $createPartitionCommand = "create partition primary"
            if ($diskSizeMB -gt $maxFat32PartitionMB) {
                $createPartitionCommand = "create partition primary size=$maxFat32PartitionMB"
                Log "Disk $diskNum is $diskSizeMB MB; creating FAT32 partition capped at $maxFat32PartitionMB MB (32 GB)."
            }

            @(
                "select disk $diskNum"
                $createPartitionCommand
                "exit"
            ) | Set-Content -Path $dpFile2 -Encoding ASCII
            Log "Creating partitions on Disk $diskNum..."
            diskpart /s $dpFile2 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }
            Remove-Item $dpFile2 -Force -ErrorAction SilentlyContinue

            SetProgress "Formatting USB partition..." 25
            Start-Sleep -Seconds 3
            Update-Disk -Number $diskNum -ErrorAction SilentlyContinue

            $partitions = Get-Partition -DiskNumber $diskNum -ErrorAction Stop
            Log "Partitions on Disk $diskNum after creation: $($partitions.Count)"
            foreach ($p in $partitions) {
                Log "  Partition $($p.PartitionNumber)  Type=$($p.Type)  Letter=$($p.DriveLetter)  Size=$([math]::Round($p.Size/1MB))MB"
            }

            $winpePart = $partitions | Where-Object { $_.Type -eq "Basic" } | Select-Object -Last 1
            if (-not $winpePart) {
                throw "Could not find the Basic partition on Disk $diskNum after creation."
            }

            # Format using Format-Volume (reliable on fresh drives; diskpart format fails
            # with 'no volume selected' when the partition has never been formatted before)
            Log "Formatting Partition $($winpePart.PartitionNumber) as FAT32 (label: $volLabel)..."
            Get-Partition -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber |
                Format-Volume -FileSystem FAT32 -NewFileSystemLabel $volLabel -Force -Confirm:$false | Out-Null
            Log "Partition $($winpePart.PartitionNumber) formatted as FAT32."

            SetProgress "Assigning drive letters..." 30
            Start-Sleep -Seconds 2
            Update-Disk -Number $diskNum -ErrorAction SilentlyContinue

            try { Remove-PartitionAccessPath -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber -AccessPath "$($winpePart.DriveLetter):" -ErrorAction SilentlyContinue } catch {}
            $usbLetter = Get-FreeDriveLetter
            if (-not $usbLetter) { throw "No free drive letters (D-Z) available to assign to the USB data partition." }
            Set-Partition -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber -NewDriveLetter $usbLetter
            Log "Assigned drive letter $usbLetter to WINPE partition (Partition $($winpePart.PartitionNumber))."
            Start-Sleep -Seconds 2

            $usbDrive = "${usbLetter}:"
            $retries = 0
            while (-not (Test-Path $usbDrive) -and $retries -lt 6) {
                $retries++
                Log "Waiting for $usbDrive to become accessible (attempt $retries/6)..."
                Start-Sleep -Seconds 2
            }
            if (-not (Test-Path $usbDrive)) { throw "Drive $usbDrive is not accessible after letter assignment." }
            Log "USB data partition: $usbDrive"

            $contentSizeBytes = (Get-ChildItem -LiteralPath $contentsDir -File -Recurse -Force -ErrorAction Stop | Measure-Object -Property Length -Sum).Sum
            if (-not $contentSizeBytes) { $contentSizeBytes = 0 }
            $usbVolume = Get-Volume -DriveLetter $usbLetter -ErrorAction Stop
            $partitionCapacityBytes = [int64]$usbVolume.Size
            $partitionFreeBytes = [int64]$usbVolume.SizeRemaining

            $contentSizeGB = [math]::Round($contentSizeBytes / 1GB, 2)
            $partitionCapacityGB = [math]::Round($partitionCapacityBytes / 1GB, 2)
            $partitionFreeGB = [math]::Round($partitionFreeBytes / 1GB, 2)

            Log "Source content size: $contentSizeGB GB. USB partition capacity: $partitionCapacityGB GB, free: $partitionFreeGB GB."

            if ($contentSizeBytes -gt $partitionCapacityBytes) {
                throw "ISO content ($contentSizeGB GB) is larger than the USB partition capacity ($partitionCapacityGB GB). Use a larger USB drive or reduce image size."
            }

            if ($contentSizeBytes -gt $partitionFreeBytes) {
                throw "Insufficient free space on USB partition. Required: $contentSizeGB GB, available: $partitionFreeGB GB."
            }

            SetProgress "Copying Windows 11 files to USB..." 45

            # Copy files; split install.wim if > 4 GB (FAT32 limit)
            $installWim = Join-Path $contentsDir "sources\install.wim"
            if (Test-Path $installWim) {
                $wimSizeMB = [math]::Round((Get-Item $installWim).Length / 1MB)
                if ($wimSizeMB -gt 3800) {
                    Log "install.wim is $wimSizeMB MB - splitting for FAT32 compatibility... This will take several minutes."
                    $splitDest = Join-Path $usbDrive "sources\install.swm"
                    New-Item -ItemType Directory -Path (Split-Path $splitDest) -Force | Out-Null
                    Split-WindowsImage -ImagePath $installWim -SplitImagePath $splitDest -FileSize 3800 -CheckIntegrity
                    Log "install.wim split complete."
                    Log "Copying remaining files to USB..."
                    & robocopy $contentsDir $usbDrive /E /XF install.wim /NFL /NDL /NJH /NJS
                } else {
                    & robocopy $contentsDir $usbDrive /E /NFL /NDL /NJH /NJS
                }
            } else {
                & robocopy $contentsDir $usbDrive /E /NFL /NDL /NJH /NJS
            }

            SetProgress "Finalising USB drive..." 90
            Log "Files copied to USB."
            SetProgress "USB write complete" 100
            Log "USB drive is ready for use."

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "USB drive created successfully!`n`nYou can now boot from this drive to install Windows 11.",
                    "USB Ready", "OK", "Info")
            })
        } catch {
            Log "ERROR during USB write: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show("USB write failed:`n`n$_", "USB Write Error", "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value            = 0
                $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $true
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}
