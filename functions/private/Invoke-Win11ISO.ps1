function Write-Win11ISOLog {
    <#
    .SYNOPSIS
        Appends a timestamped message to the Win11ISO status log TextBox.
    .PARAMETER Message
        The message to append.
    #>
    param([string]$Message)
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
        $current = $sync["WPFWin11ISOStatusLog"].Text
        if ($current -eq "Ready. Please select a Windows 11 ISO to begin.") {
            $sync["WPFWin11ISOStatusLog"].Text = "[$timestamp] $Message"
        } else {
            $sync["WPFWin11ISOStatusLog"].Text += "`n[$timestamp] $Message"
        }
        $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
    })
}

function Invoke-WinUtilISOBrowse {
    <#
    .SYNOPSIS
        Opens an OpenFileDialog so the user can choose a Windows 11 ISO file.
        Populates WPFWin11ISOPath and reveals the Mount & Verify section (Step 2).
    #>
    Add-Type -AssemblyName System.Windows.Forms

    $dlg = [System.Windows.Forms.OpenFileDialog]::new()
    $dlg.Title  = "Select Windows 11 ISO"
    $dlg.Filter = "ISO files (*.iso)|*.iso|All files (*.*)|*.*"
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $isoPath = $dlg.FileName

    # ── Basic size sanity-check (a Win11 ISO is typically > 4 GB) ──
    $fileSizeGB = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)

    $sync["WPFWin11ISOPath"].Text = $isoPath
    $sync["WPFWin11ISOFileInfo"].Text      = "File size: $fileSizeGB GB"
    $sync["WPFWin11ISOFileInfo"].Visibility = "Visible"

    # Reveal Step 2
    $sync["WPFWin11ISOMountSection"].Visibility = "Visible"

    # Collapse all later steps whenever a new ISO is chosen
    $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility     = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility     = "Collapsed"

    Write-Win11ISOLog "ISO selected: $isoPath  ($fileSizeGB GB)"
}

function Invoke-WinUtilISOMountAndVerify {
    <#
    .SYNOPSIS
        Mounts the selected ISO, verifies it is a valid Windows 11 image,
        and populates the edition list.  Reveals Step 3 on success.
    #>
    $isoPath = $sync["WPFWin11ISOPath"].Text

    if ([string]::IsNullOrWhiteSpace($isoPath) -or $isoPath -eq "No ISO selected...") {
        [System.Windows.MessageBox]::Show(
            "Please select an ISO file first.",
            "No ISO Selected", "OK", "Warning")
        return
    }

    Write-Win11ISOLog "Mounting ISO: $isoPath"
    Set-WinUtilProgressBar -Label "Mounting ISO..." -Percent 10

    try {
        # Mount the ISO
        $diskImage = Mount-DiskImage -ImagePath $isoPath -PassThru -ErrorAction Stop
        $driveLetter = ($diskImage | Get-Volume).DriveLetter + ":"
        Write-Win11ISOLog "Mounted at drive $driveLetter"

        Set-WinUtilProgressBar -Label "Verifying ISO contents..." -Percent 30

        # ── Verify install.wim / install.esd presence ──
        $wimPath = Join-Path $driveLetter "sources\install.wim"
        $esdPath = Join-Path $driveLetter "sources\install.esd"

        if (-not (Test-Path $wimPath) -and -not (Test-Path $esdPath)) {
            Dismount-DiskImage -ImagePath $isoPath | Out-Null
            Write-Win11ISOLog "ERROR: install.wim/install.esd not found — not a valid Windows ISO."
            [System.Windows.MessageBox]::Show(
                "This does not appear to be a valid Windows ISO.`n`ninstall.wim / install.esd was not found.",
                "Invalid ISO", "OK", "Error")
            Set-WinUtilProgressBar -Label "" -Percent 0
            return
        }

        $activeWim = if (Test-Path $wimPath) { $wimPath } else { $esdPath }

        # ── Read edition / architecture info ──
        Set-WinUtilProgressBar -Label "Reading image metadata..." -Percent 55

        $editions = Get-WindowsImage -ImagePath $activeWim | Select-Object -ExpandProperty ImageName

        # ── Verify at least one Win11 edition is present ──
        $isWin11 = $editions | Where-Object { $_ -match "Windows 11" }
        if (-not $isWin11) {
            Dismount-DiskImage -ImagePath $isoPath | Out-Null
            Write-Win11ISOLog "ERROR: No 'Windows 11' edition found in the image."
            [System.Windows.MessageBox]::Show(
                "No Windows 11 edition was found in this ISO.`n`nOnly official Windows 11 ISOs are supported.",
                "Not a Windows 11 ISO", "OK", "Error")
            Set-WinUtilProgressBar -Label "" -Percent 0
            return
        }

        # ── Populate UI ──
        $sync["WPFWin11ISOMountDriveLetter"].Text = "Mounted at: $driveLetter   |   Image file: $(Split-Path $activeWim -Leaf)"
        $sync["WPFWin11ISOEditionList"].Text       = ($editions -join "`n")
        $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Visible"

        # Store for later steps
        $sync["Win11ISODriveLetter"] = $driveLetter
        $sync["Win11ISOWimPath"]     = $activeWim
        $sync["Win11ISOImagePath"]   = $isoPath

        # Reveal Step 3
        $sync["WPFWin11ISOModifySection"].Visibility = "Visible"

        Set-WinUtilProgressBar -Label "ISO verified ✔" -Percent 100
        Write-Win11ISOLog "ISO verified OK.  Editions found: $($editions.Count)"
    }
    catch {
        Write-Win11ISOLog "ERROR during mount/verify: $_"
        [System.Windows.MessageBox]::Show(
            "An error occurred while mounting or verifying the ISO:`n`n$_",
            "Error", "OK", "Error")
    }
    finally {
        Start-Sleep -Milliseconds 800
        Set-WinUtilProgressBar -Label "" -Percent 0
    }
}

function Invoke-WinUtilISOModify {
    <#
    .SYNOPSIS
        Extracts ISO contents to a temp working directory, modifies install.wim,
        then repackages the image.  Reveals Step 4 (output options) on success.

    .NOTES
        This function runs inside a PowerShell runspace so the UI stays responsive.
        Placeholder modification logic is provided; extend as needed.
    #>

    $isoPath    = $sync["Win11ISOImagePath"]
    $driveLetter= $sync["Win11ISODriveLetter"]
    $wimPath    = $sync["Win11ISOWimPath"]

    if (-not $isoPath) {
        [System.Windows.MessageBox]::Show(
            "No verified ISO found.  Please complete Steps 1 and 2 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    # Disable the modify button to prevent double-click
    $sync["WPFWin11ISOModifyButton"].IsEnabled = $false

    $workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    # ── Run modification in a background runspace ──
    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync",         $sync)
    $runspace.SessionStateProxy.SetVariable("isoPath",      $isoPath)
    $runspace.SessionStateProxy.SetVariable("driveLetter",  $driveLetter)
    $runspace.SessionStateProxy.SetVariable("wimPath",      $wimPath)
    $runspace.SessionStateProxy.SetVariable("workDir",      $workDir)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({

        function Log($msg) {
            $ts = (Get-Date).ToString("HH:mm:ss")
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text += "`n[$ts] $msg"
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                Set-WinUtilProgressBar -Label $label -Percent $pct
            })
        }

        try {
            # ── 1. Create working directory structure ──
            Log "Creating working directory: $workDir"
            $isoContents = Join-Path $workDir "iso_contents"
            $mountDir     = Join-Path $workDir "wim_mount"
            New-Item -ItemType Directory -Path $isoContents, $mountDir -Force | Out-Null
            SetProgress "Copying ISO contents..." 10

            # ── 2. Copy all ISO contents to the working directory ──
            Log "Copying ISO contents from $driveLetter to $isoContents..."
            $robocopyArgs = @($driveLetter, $isoContents, "/E", "/NFL", "/NDL", "/NJH", "/NJS")
            & robocopy @robocopyArgs | Out-Null
            Log "ISO contents copied."
            SetProgress "Mounting install.wim..." 25

            # ── 3. Copy install.wim to working dir (it may be read-only on the DVD) ──
            $localWim = Join-Path $isoContents "sources\install.wim"
            if (-not (Test-Path $localWim)) {
                # ESD path
                $localWim = Join-Path $isoContents "sources\install.esd"
            }
            # Ensure the file is writable
            Set-ItemProperty -Path $localWim -Name IsReadOnly -Value $false

            # ── 4. Mount the first index of install.wim ──
            Log "Mounting install.wim (Index 1) at $mountDir..."
            Mount-WindowsImage -ImagePath $localWim -Index 1 -Path $mountDir -ErrorAction Stop | Out-Null
            SetProgress "Modifying install.wim..." 45

            # ════════════════════════════════════════════════════════
            #  >>>  YOUR MODIFICATION LOGIC GOES HERE  <<<
            #
            #  Examples (uncomment or extend as needed):
            #
            #  Remove-WindowsPackage  -Path $mountDir -PackageName "Microsoft-Windows-…"
            #  Disable-WindowsOptionalFeature -Path $mountDir -FeatureName "…"
            #  Copy-Item "C:\path\to\custom.xml" "$mountDir\Windows\Panther\unattend.xml"
            #  reg load "HKLM\OFFLINE" "$mountDir\Windows\System32\config\SOFTWARE"
            #  … registry tweaks …
            #  reg unload "HKLM\OFFLINE"
            #
            # ════════════════════════════════════════════════════════

            Log "Applying modifications to install.wim... (placeholder)"
            Start-Sleep -Seconds 2   # replace with actual modification calls

            # ── 5. Save and dismount the WIM ──
            SetProgress "Saving modified install.wim..." 65
            Log "Dismounting and saving install.wim..."
            Dismount-WindowsImage -Path $mountDir -Save -ErrorAction Stop | Out-Null
            Log "install.wim saved."
            SetProgress "Dismounting source ISO..." 80

            # ── 6. Dismount the original ISO ──
            Log "Dismounting original ISO..."
            Dismount-DiskImage -ImagePath $isoPath | Out-Null

            # Store work directory for output steps
            $sync["Win11ISOWorkDir"]      = $workDir
            $sync["Win11ISOContentsDir"]  = $isoContents

            SetProgress "Modification complete ✔" 100
            Log "install.wim modification complete.  Select an output option in Step 4."

            # ── Reveal Step 4 on the UI thread ──
            $sync["WPFWin11ISOOutputSection"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"
                Invoke-WinUtilISORefreshUSBDrives
            })
        }
        catch {
            Log "ERROR during modification: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred during install.wim modification:`n`n$_",
                    "Modification Error", "OK", "Error")
            })
        }
        finally {
            Start-Sleep -Milliseconds 800
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                Set-WinUtilProgressBar -Label "" -Percent 0
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}

function Invoke-WinUtilISOExport {
    <#
    .SYNOPSIS
        Saves the modified ISO contents as a new bootable ISO file.
        Uses oscdimg.exe (part of the Windows ADK) if present; falls back
        to a reminder message if not installed.
    #>
    $contentsDir = $sync["Win11ISOContentsDir"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show(
            "No modified ISO content found.  Please complete Steps 1–3 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    Add-Type -AssemblyName System.Windows.Forms

    $dlg = [System.Windows.Forms.SaveFileDialog]::new()
    $dlg.Title            = "Save Modified Windows 11 ISO"
    $dlg.Filter           = "ISO files (*.iso)|*.iso"
    $dlg.FileName         = "Win11_Modified_$(Get-Date -Format 'yyyyMMdd').iso"
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $outputISO = $dlg.FileName
    Write-Win11ISOLog "Exporting to ISO: $outputISO"
    Set-WinUtilProgressBar -Label "Building ISO..." -Percent 10

    # Locate oscdimg.exe (Windows ADK)
    $oscdimg = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
               Select-Object -First 1 -ExpandProperty FullName

    if (-not $oscdimg) {
        Set-WinUtilProgressBar -Label "" -Percent 0
        Write-Win11ISOLog "oscdimg.exe not found.  Install Windows ADK to enable ISO export."
        [System.Windows.MessageBox]::Show(
            "oscdimg.exe was not found.`n`nTo export an ISO you need the Windows Assessment and Deployment Kit (ADK).`n`nDownload it from: https://learn.microsoft.com/windows-hardware/get-started/adk-install",
            "Windows ADK Required", "OK", "Warning")
        return
    }

    # Build boot parameters (BIOS + UEFI dual-boot)
    $bootData   = "2#p0,e,b`"$contentsDir\boot\etfsboot.com`"#pEF,e,b`"$contentsDir\efi\microsoft\boot\efisys.bin`""
    $oscdimgArgs = @(
        "-m",           # ignore source path max size
        "-o",           # optimise storage
        "-u2",          # UDF 2.01
        "-udfver102",
        "-bootdata:$bootData",
        "-l`"CTOS_MODIFIED`"",
        "`"$contentsDir`"",
        "`"$outputISO`""
    )

    try {
        Write-Win11ISOLog "Running oscdimg..."
        $proc = Start-Process -FilePath $oscdimg -ArgumentList $oscdimgArgs -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0) {
            Set-WinUtilProgressBar -Label "ISO exported ✔" -Percent 100
            Write-Win11ISOLog "ISO exported successfully: $outputISO"
            [System.Windows.MessageBox]::Show(
                "ISO exported successfully!`n`n$outputISO",
                "Export Complete", "OK", "Info")
        } else {
            Write-Win11ISOLog "oscdimg exited with code $($proc.ExitCode)."
            [System.Windows.MessageBox]::Show(
                "oscdimg exited with code $($proc.ExitCode).`nCheck the status log for details.",
                "Export Error", "OK", "Error")
        }
    }
    catch {
        Write-Win11ISOLog "ERROR during ISO export: $_"
        [System.Windows.MessageBox]::Show("ISO export failed:`n`n$_","Error","OK","Error")
    }
    finally {
        Start-Sleep -Milliseconds 800
        Set-WinUtilProgressBar -Label "" -Percent 0
    }
}

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
        $label     = "Disk $($disk.Number): $($disk.FriendlyName)  [$sizeGB GB]  — $($disk.PartitionStyle)"
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
            "No modified ISO content found.  Please complete Steps 1–3 first.",
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
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
        }
        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                Set-WinUtilProgressBar -Label $label -Percent $pct
            })
        }

        try {
            SetProgress "Formatting USB drive..." 10

            # ── Diskpart script: clean, GPT, create ESP + data partitions ──
            $dpScript = @"
select disk $diskNum
clean
convert gpt
create partition efi size=512
format quick fs=fat32 label="SYSTEM"
assign
create partition primary
format quick fs=fat32 label="WINPE"
assign
exit
"@
            $dpFile = Join-Path $env:TEMP "winutil_diskpart_$(Get-Random).txt"
            $dpScript | Set-Content -Path $dpFile -Encoding ASCII
            Log "Running diskpart on Disk $diskNum..."
            diskpart /s $dpFile | Out-Null
            Remove-Item $dpFile -Force

            SetProgress "Identifying USB partitions..." 30
            Start-Sleep -Seconds 3   # let Windows assign drive letters

            # Find newly assigned drive letter for the data partition
            $usbVol = Get-Partition -DiskNumber $diskNum |
                      Where-Object { $_.Type -eq "Basic" } |
                      Get-Volume |
                      Where-Object { $_.FileSystemLabel -eq "WINPE" } |
                      Select-Object -First 1

            if (-not $usbVol) {
                throw "Could not locate the formatted USB data partition.  Drive letter may not have been assigned automatically."
            }

            $usbDrive = "$($usbVol.DriveLetter):"
            Log "USB data partition: $usbDrive"
            SetProgress "Copying Windows 11 files to USB..." 45

            # ── Copy files (split large install.wim if > 4 GB for FAT32) ──
            $installWim = Join-Path $contentsDir "sources\install.wim"
            if (Test-Path $installWim) {
                $wimSizeMB = [math]::Round((Get-Item $installWim).Length / 1MB)
                if ($wimSizeMB -gt 3800) {
                    # FAT32 limit – split with DISM
                    Log "install.wim is $wimSizeMB MB – splitting for FAT32 compatibility..."
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
                Set-WinUtilProgressBar -Label "" -Percent 0
                $sync["WPFWin11ISOWriteUSBButton"].IsEnabled = $true
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}
