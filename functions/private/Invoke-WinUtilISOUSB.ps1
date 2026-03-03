function Invoke-WinUtilISORefreshUSBDrives {
    $combo    = $sync["WPFWin11ISOUSBDriveComboBox"]
    $removable = Get-Disk | Where-Object { $_.BusType -eq "USB" } | Sort-Object Number

    $combo.Items.Clear()

    if ($removable.Count -eq 0) {
        $combo.Items.Add("No USB drives detected")
        $combo.SelectedIndex = 0
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

    $selectedIndex = $sync["WPFWin11ISOUSBDriveComboBox"].SelectedIndex
    if ($selectedIndex -lt 0 -or -not $usbDisks -or $selectedIndex -ge $usbDisks.Count) {
        [System.Windows.MessageBox]::Show("Please select a USB drive from the dropdown.", "No Drive Selected", "OK", "Warning")
        return
    }

    $targetDisk = $usbDisks[$selectedIndex]
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

            # Phase 1: Clean disk via diskpart
            $dpFile1 = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
            "select disk $diskNum`nclean`nexit" | Set-Content -Path $dpFile1 -Encoding ASCII
            Log "Running diskpart clean on Disk $diskNum..."
            diskpart /s $dpFile1 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }
            Remove-Item $dpFile1 -Force -ErrorAction SilentlyContinue

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

            # Phase 3: Create FAT32 partition via diskpart
            $volLabel = "W11-" + (Get-Date).ToString('yyMMdd')
            $dpFile2  = Join-Path $env:TEMP "winutil_diskpart2_$(Get-Random).txt"
            "select disk $diskNum`ncreate partition primary`nformat quick fs=exfat label=`"$volLabel`"`nexit" |
                Set-Content -Path $dpFile2 -Encoding ASCII
            Log "Creating partitions on Disk $diskNum..."
            diskpart /s $dpFile2 2>&1 | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }
            Remove-Item $dpFile2 -Force -ErrorAction SilentlyContinue

            SetProgress "Assigning drive letters..." 30
            Start-Sleep -Seconds 3
            Update-Disk -Number $diskNum -ErrorAction SilentlyContinue

            $partitions = Get-Partition -DiskNumber $diskNum -ErrorAction Stop
            Log "Partitions on Disk $diskNum after format: $($partitions.Count)"
            foreach ($p in $partitions) {
                Log "  Partition $($p.PartitionNumber)  Type=$($p.Type)  Letter=$($p.DriveLetter)  Size=$([math]::Round($p.Size/1MB))MB"
            }

            $winpePart = $partitions | Where-Object { $_.Type -eq "Basic" } | Select-Object -Last 1
            if (-not $winpePart) {
                throw "Could not find the WINPE (Basic) partition on Disk $diskNum after format."
            }

            try { Remove-PartitionAccessPath -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber -AccessPath "$($winpePart.DriveLetter):" -ErrorAction SilentlyContinue } catch {}
            $usbLetter = Get-FreeDriveLetter
            if (-not $usbLetter) { throw "No free drive letters (D-Z) available to assign to the USB data partition." }
            Set-Partition -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber -NewDriveLetter $usbLetter
            Log "Assigned drive letter $usbLetter to WINPE partition (Partition $($winpePart.PartitionNumber))."
            Start-Sleep -Seconds 2

            $usbDrive = "${usbLetter}:"
            if (-not (Test-Path $usbDrive)) { throw "Drive $usbDrive is not accessible after letter assignment." }
            Log "USB data partition: $usbDrive"
            SetProgress "Copying Windows 11 files to USB..." 45

            # Copy files (exFAT supports files > 4 GB, no splitting needed)
            & robocopy $contentsDir $usbDrive /E /NFL /NDL /NJH /NJS

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
