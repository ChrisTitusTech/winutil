function Invoke-WinUtilISORefreshUSBDrives {
    <#
    .SYNOPSIS
        Populates the USB drive ComboBox with all currently attached removable drives.
    #>
    $combo = $sync["WPFWin11ISOUSBDriveComboBox"]
    $combo.Items.Clear()

    $removable = Get-Disk | Where-Object { $_.BusType -eq "USB" } | Sort-Object Number

    if ($removable.Count -eq 0) {
        $combo.Items.Add("No USB drives detected")
        $combo.SelectedIndex = 0
        Write-Win11ISOLog "No USB drives detected."
        return
    }

    foreach ($disk in $removable) {
        $sizeGB    = [math]::Round($disk.Size / 1GB, 1)
        $label     = "Disk $($disk.Number): $($disk.FriendlyName)  [$sizeGB GB] - $($disk.PartitionStyle)"
        $combo.Items.Add($label)
    }
    $combo.SelectedIndex = 0
    Write-Win11ISOLog "Found $($removable.Count) USB drive(s)."

    # Store disk objects for later use
    $sync["Win11ISOUSBDisks"] = $removable
}

function Invoke-WinUtilISOWriteUSB {
    <#
    .SYNOPSIS
        Erases the selected USB drive and writes the modified Windows 11 ISO
        content as a bootable installation drive (using DISM / robocopy approach).
    #>
    $contentsDir = $sync["Win11ISOContentsDir"]
    $usbDisks    = $sync["Win11ISOUSBDisks"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show(
            "No modified ISO content found.  Please complete Steps 1-3 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    $selectedIndex = $sync["WPFWin11ISOUSBDriveComboBox"].SelectedIndex
    if ($selectedIndex -lt 0 -or -not $usbDisks -or $selectedIndex -ge $usbDisks.Count) {
        [System.Windows.MessageBox]::Show(
            "Please select a USB drive from the dropdown.",
            "No Drive Selected", "OK", "Warning")
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
    $runspace.SessionStateProxy.SetVariable("sync",         $sync)
    $runspace.SessionStateProxy.SetVariable("diskNum",      $diskNum)
    $runspace.SessionStateProxy.SetVariable("contentsDir",  $contentsDir)

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

        try {
            SetProgress "Formatting USB drive..." 10

            # ── Helper: find a free drive letter (D-Z) ──────────────────────────
            function Get-FreeDriveLetter {
                $used = (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue).Name
                foreach ($c in [char[]](68..90)) {   # D..Z
                    if ($used -notcontains [string]$c) { return $c }
                }
                return $null
            }

            # ── Phase 1: Clean the disk via diskpart ────────────────────────────
            # Only run "clean" here.  "convert gpt" in diskpart requires the disk to
            # already be MBR; after a clean the disk is RAW, so convert gpt fails on
            # many systems.  We use Initialize-Disk (which accepts RAW disks) instead.
            $dpScript1 = @"
select disk $diskNum
clean
exit
"@
            $dpFile1 = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
            $dpScript1 | Set-Content -Path $dpFile1 -Encoding ASCII
            Log "Running diskpart clean on Disk $diskNum..."
            $dpOut1 = diskpart /s $dpFile1 2>&1
            Remove-Item $dpFile1 -Force -ErrorAction SilentlyContinue
            $dpOut1 | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }

            # ── Phase 2: Initialize as GPT via PowerShell ────────────────────────
            # After "clean", Windows may still see the disk as initialized (stale
            # metadata).  Initialize-Disk only accepts RAW disks; Set-Disk handles
            # already-initialized (MBR/GPT) disks with no partitions.  Try both.
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

            # ── Phase 3: Create partitions via diskpart ──────────────────────────
            # "create partition efi" is not supported on removable media.
            # A single FAT32 primary partition is all that is needed for a UEFI-
            # bootable Windows install USB – the firmware locates \EFI\Boot\bootx64.efi
            # on any FAT32 volume regardless of GPT partition type.
            $dpScript2 = @"
select disk $diskNum
create partition primary
format quick fs=fat32 label="WINPE"
exit
"@
            $dpFile2 = Join-Path $env:TEMP "winutil_diskpart2_$(Get-Random).txt"
            $dpScript2 | Set-Content -Path $dpFile2 -Encoding ASCII
            Log "Creating partitions on Disk $diskNum..."
            $dpOut2 = diskpart /s $dpFile2 2>&1
            Remove-Item $dpFile2 -Force -ErrorAction SilentlyContinue
            $dpOut2 | Where-Object { $_ -match '\S' } | ForEach-Object { Log "  diskpart: $_" }

            SetProgress "Assigning drive letters..." 30
            Start-Sleep -Seconds 3   # allow Windows to settle after partition creation
            Update-Disk -Number $diskNum -ErrorAction SilentlyContinue

            # ── Explicitly assign drive letters via PowerShell ───────────────────
            # This is reliable regardless of registry state, unlike diskpart assign.
            $partitions = Get-Partition -DiskNumber $diskNum -ErrorAction Stop
            Log "Partitions on Disk $diskNum after format: $($partitions.Count)"
            foreach ($p in $partitions) {
                Log "  Partition $($p.PartitionNumber)  Type=$($p.Type)  Letter=$($p.DriveLetter)  Size=$([math]::Round($p.Size/1MB))MB"
            }

            $winpePart = $partitions | Where-Object { $_.Type -eq "Basic" } | Select-Object -Last 1

            if (-not $winpePart) {
                throw "Could not find the WINPE (Basic) partition on Disk $diskNum after format."
            }

            # Remove stale letter first (noops if none), then assign a fresh one
            try { Remove-PartitionAccessPath -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber -AccessPath "$($winpePart.DriveLetter):" -ErrorAction SilentlyContinue } catch {}
            $usbLetter = Get-FreeDriveLetter
            if (-not $usbLetter) { throw "No free drive letters (D-Z) available to assign to the USB data partition." }
            Set-Partition -DiskNumber $diskNum -PartitionNumber $winpePart.PartitionNumber -NewDriveLetter $usbLetter
            Log "Assigned drive letter $usbLetter to WINPE partition (Partition $($winpePart.PartitionNumber))."
            Start-Sleep -Seconds 2

            $usbDrive = "${usbLetter}:"
            if (-not (Test-Path $usbDrive)) {
                throw "Drive $usbDrive is not accessible after letter assignment."
            }
            Log "USB data partition: $usbDrive"
            SetProgress "Copying Windows 11 files to USB..." 45

            # ── Copy files (split large install.wim if > 4 GB for FAT32) ──
            $installWim = Join-Path $contentsDir "sources\install.wim"
            if (Test-Path $installWim) {
                $wimSizeMB = [math]::Round((Get-Item $installWim).Length / 1MB)
                if ($wimSizeMB -gt 3800) {
                    # FAT32 limit – split with DISM
                    Log "install.wim is $wimSizeMB MB - splitting for FAT32 compatibility...This will take several minutes."
                    $splitDest = Join-Path $usbDrive "sources\install.swm"
                    New-Item -ItemType Directory -Path (Split-Path $splitDest) -Force | Out-Null
                    Split-WindowsImage -ImagePath $installWim `
                                       -SplitImagePath $splitDest `
                                       -FileSize 3800 -CheckIntegrity | Out-Null
                    Log "install.wim split complete."

                    # Copy everything else (exclude install.wim)
                    $robocopyArgs = @($contentsDir, $usbDrive, "/E", "/XF", "install.wim", "/NFL", "/NDL", "/NJH", "/NJS")
                    & robocopy @robocopyArgs | Out-Null
                } else {
                    & robocopy $contentsDir $usbDrive /E /NFL /NDL /NJH /NJS | Out-Null
                }
            } else {
                & robocopy $contentsDir $usbDrive /E /NFL /NDL /NJH /NJS | Out-Null
            }

            SetProgress "Finalising USB drive..." 90
            Log "Files copied to USB."

            SetProgress "USB write complete ✔" 100
            Log "USB drive is ready for use."

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "USB drive created successfully!`n`nYou can now boot from this drive to install Windows 11.",
                    "USB Ready", "OK", "Info")
            })
        }
        catch {
            Log "ERROR during USB write: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "USB write failed:`n`n$_",
                    "USB Write Error", "OK", "Error")
            })
        }
        finally {
            Start-Sleep -Milliseconds 800
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0
                $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $true
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}
