function Write-Win11ISOLog {
    param([string]$Message)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
        $current = $sync["WPFWin11ISOStatusLog"].Text
        if ($current -eq "Ready. Please select a Windows 11 ISO to begin.") {
            $sync["WPFWin11ISOStatusLog"].Text = "[$ts] $Message"
        } else {
            $sync["WPFWin11ISOStatusLog"].Text += "`n[$ts] $Message"
        }
        $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
        $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
    })
}

function Invoke-WinUtilISOBrowse {
    Add-Type -AssemblyName System.Windows.Forms

    $dlg = [System.Windows.Forms.OpenFileDialog]::new()
    $dlg.Title            = "Select Windows 11 ISO"
    $dlg.Filter           = "ISO files (*.iso)|*.iso|All files (*.*)|*.*"
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $isoPath    = $dlg.FileName
    $fileSizeGB = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)

    $sync["WPFWin11ISOPath"].Text           = $isoPath
    $sync["WPFWin11ISOFileInfo"].Text       = "File size: $fileSizeGB GB"
    $sync["WPFWin11ISOFileInfo"].Visibility = "Visible"
    $sync["WPFWin11ISOMountSection"].Visibility       = "Visible"
    $sync["WPFWin11ISOVerifyResultPanel"].Visibility  = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility      = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility      = "Collapsed"

    Write-Win11ISOLog "ISO selected: $isoPath  ($fileSizeGB GB)"
}

function Invoke-WinUtilISOMountAndVerify {
    $isoPath = $sync["WPFWin11ISOPath"].Text

    if ([string]::IsNullOrWhiteSpace($isoPath) -or $isoPath -eq "No ISO selected...") {
        [System.Windows.MessageBox]::Show("Please select an ISO file first.", "No ISO Selected", "OK", "Warning")
        return
    }

    Write-Win11ISOLog "Mounting ISO: $isoPath"
    Set-WinUtilProgressBar -Label "Mounting ISO..." -Percent 10

    try {
        Mount-DiskImage -ImagePath $isoPath -ErrorAction Stop | Out-Null

        do {
            Start-Sleep -Milliseconds 500
        } until ((Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter)

        $driveLetter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter + ":"
        Write-Win11ISOLog "Mounted at drive $driveLetter"

        Set-WinUtilProgressBar -Label "Verifying ISO contents..." -Percent 30

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

        Set-WinUtilProgressBar -Label "Reading image metadata..." -Percent 55
        $imageInfo = Get-WindowsImage -ImagePath $activeWim | Select-Object ImageIndex, ImageName

        if (-not ($imageInfo | Where-Object { $_.ImageName -match "Windows 11" })) {
            Dismount-DiskImage -ImagePath $isoPath | Out-Null
            Write-Win11ISOLog "ERROR: No 'Windows 11' edition found in the image."
            [System.Windows.MessageBox]::Show(
                "No Windows 11 edition was found in this ISO.`n`nOnly official Windows 11 ISOs are supported.",
                "Not a Windows 11 ISO", "OK", "Error")
            Set-WinUtilProgressBar -Label "" -Percent 0
            return
        }

        $sync["Win11ISOImageInfo"] = $imageInfo

        $sync["WPFWin11ISOMountDriveLetter"].Text = "Mounted at: $driveLetter   |   Image file: $(Split-Path $activeWim -Leaf)"
        $sync["WPFWin11ISOEditionComboBox"].Dispatcher.Invoke([action]{
            $sync["WPFWin11ISOEditionComboBox"].Items.Clear()
            foreach ($img in $imageInfo) {
                [void]$sync["WPFWin11ISOEditionComboBox"].Items.Add("$($img.ImageIndex): $($img.ImageName)")
            }
            if ($sync["WPFWin11ISOEditionComboBox"].Items.Count -gt 0) {
                $proIndex = -1
                for ($i = 0; $i -lt $sync["WPFWin11ISOEditionComboBox"].Items.Count; $i++) {
                    if ($sync["WPFWin11ISOEditionComboBox"].Items[$i] -match "Windows 11 Pro(?![\w ])") {
                        $proIndex = $i; break
                    }
                }
                $sync["WPFWin11ISOEditionComboBox"].SelectedIndex = if ($proIndex -ge 0) { $proIndex } else { 0 }
            }
        })
        $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Visible"

        $sync["Win11ISODriveLetter"] = $driveLetter
        $sync["Win11ISOWimPath"]     = $activeWim
        $sync["Win11ISOImagePath"]   = $isoPath
        $sync["WPFWin11ISOModifySection"].Visibility = "Visible"

        Set-WinUtilProgressBar -Label "ISO verified" -Percent 100
        Write-Win11ISOLog "ISO verified OK.  Editions found: $($imageInfo.Count)"
    } catch {
        Write-Win11ISOLog "ERROR during mount/verify: $_"
        [System.Windows.MessageBox]::Show(
            "An error occurred while mounting or verifying the ISO:`n`n$_",
            "Error", "OK", "Error")
    } finally {
        Start-Sleep -Milliseconds 800
        Set-WinUtilProgressBar -Label "" -Percent 0
    }
}

function Invoke-WinUtilISOModify {
    $isoPath     = $sync["Win11ISOImagePath"]
    $driveLetter = $sync["Win11ISODriveLetter"]
    $wimPath     = $sync["Win11ISOWimPath"]

    if (-not $isoPath) {
        [System.Windows.MessageBox]::Show(
            "No verified ISO found.  Please complete Steps 1 and 2 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    $selectedItem     = $sync["WPFWin11ISOEditionComboBox"].SelectedItem
    $selectedWimIndex = 1
    if ($selectedItem -and $selectedItem -match '^(\d+):') {
        $selectedWimIndex = [int]$Matches[1]
    } elseif ($sync["Win11ISOImageInfo"]) {
        $selectedWimIndex = $sync["Win11ISOImageInfo"][0].ImageIndex
    }
    $selectedEditionName = if ($selectedItem) { ($selectedItem -replace '^\d+:\s*', '') } else { "Unknown" }
    Write-Win11ISOLog "Selected edition: $selectedEditionName (Index $selectedWimIndex)"

    $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
    $sync["Win11ISOModifying"] = $true

    $existingWorkDir = Get-Item -Path (Join-Path $env:TEMP "WinUtil_Win11ISO*") -ErrorAction SilentlyContinue |
        Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $workDir = if ($existingWorkDir) {
        Write-Win11ISOLog "Reusing existing temp directory: $($existingWorkDir.FullName)"
        $existingWorkDir.FullName
    } else {
        Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }

    $autounattendContent = if ($WinUtilAutounattendXml) {
        $WinUtilAutounattendXml
    } else {
        $toolsXml = Join-Path $PSScriptRoot "..\..\tools\autounattend.xml"
        if (Test-Path $toolsXml) { Get-Content $toolsXml -Raw } else { "" }
    }

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $injectDrivers = $sync["WPFWin11ISOInjectDrivers"].IsChecked -eq $true

    $runspace.SessionStateProxy.SetVariable("sync",                $sync)
    $runspace.SessionStateProxy.SetVariable("isoPath",             $isoPath)
    $runspace.SessionStateProxy.SetVariable("driveLetter",         $driveLetter)
    $runspace.SessionStateProxy.SetVariable("wimPath",             $wimPath)
    $runspace.SessionStateProxy.SetVariable("workDir",             $workDir)
    $runspace.SessionStateProxy.SetVariable("selectedWimIndex",    $selectedWimIndex)
    $runspace.SessionStateProxy.SetVariable("selectedEditionName", $selectedEditionName)
    $runspace.SessionStateProxy.SetVariable("autounattendContent", $autounattendContent)
    $runspace.SessionStateProxy.SetVariable("injectDrivers",       $injectDrivers)

    $isoScriptFuncDef   = "function Invoke-WinUtilISOScript {`n" + ${function:Invoke-WinUtilISOScript}.ToString() + "`n}"
    $win11ISOLogFuncDef = "function Write-Win11ISOLog {`n"       + ${function:Write-Win11ISOLog}.ToString()       + "`n}"
    $runspace.SessionStateProxy.SetVariable("isoScriptFuncDef",   $isoScriptFuncDef)
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($isoScriptFuncDef))
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        function Log($msg) {
            $ts = (Get-Date).ToString("HH:mm:ss")
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text += "`n[$ts] $msg"
                $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
            Add-Content -Path (Join-Path $workDir "WinUtil_Win11ISO.log") -Value "[$ts] $msg" -ErrorAction SilentlyContinue
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value            = [Math]::Max($pct, 5)
            })
        }

        try {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility  = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
            })

            Log "Creating working directory: $workDir"
            $isoContents = Join-Path $workDir "iso_contents"
            $mountDir    = Join-Path $workDir "wim_mount"
            New-Item -ItemType Directory -Path $isoContents, $mountDir -Force | Out-Null
            SetProgress "Copying ISO contents..." 10

            Log "Copying ISO contents from $driveLetter to $isoContents..."
            & robocopy $driveLetter $isoContents /E /NFL /NDL /NJH /NJS | Out-Null
            Log "ISO contents copied."
            SetProgress "Mounting install.wim..." 25

            $localWim = Join-Path $isoContents "sources\install.wim"
            if (-not (Test-Path $localWim)) { $localWim = Join-Path $isoContents "sources\install.esd" }
            Set-ItemProperty -Path $localWim -Name IsReadOnly -Value $false

            Log "Mounting install.wim (Index ${selectedWimIndex}: $selectedEditionName) at $mountDir..."
            Mount-WindowsImage -ImagePath $localWim -Index $selectedWimIndex -Path $mountDir -ErrorAction Stop | Out-Null
            SetProgress "Modifying install.wim..." 45

            Log "Applying WinUtil modifications to install.wim..."
            Invoke-WinUtilISOScript -ScratchDir $mountDir -ISOContentsDir $isoContents -AutoUnattendXml $autounattendContent -InjectCurrentSystemDrivers $injectDrivers -Log { param($m) Log $m }

            SetProgress "Cleaning up component store (WinSxS)..." 56
            Log "Running DISM component store cleanup (/ResetBase)..."
            & dism /English "/image:$mountDir" /Cleanup-Image /StartComponentCleanup /ResetBase | ForEach-Object { Log $_ }
            Log "Component store cleanup complete."

            SetProgress "Saving modified install.wim..." 65
            Log "Dismounting and saving install.wim. This will take several minutes..."
            Dismount-WindowsImage -Path $mountDir -Save -ErrorAction Stop | Out-Null
            Log "install.wim saved."

            SetProgress "Removing unused editions from install.wim..." 70
            Log "Exporting edition '$selectedEditionName' (Index $selectedWimIndex) to a single-edition install.wim..."
            $exportWim = Join-Path $isoContents "sources\install_export.wim"
            Export-WindowsImage -SourceImagePath $localWim -SourceIndex $selectedWimIndex -DestinationImagePath $exportWim -ErrorAction Stop | Out-Null
            Remove-Item -Path $localWim -Force
            Rename-Item -Path $exportWim -NewName "install.wim" -Force
            $localWim = Join-Path $isoContents "sources\install.wim"
            Log "Unused editions removed. install.wim now contains only '$selectedEditionName'."

            SetProgress "Dismounting source ISO..." 80
            Log "Dismounting original ISO..."
            Dismount-DiskImage -ImagePath $isoPath | Out-Null

            $sync["Win11ISOWorkDir"]     = $workDir
            $sync["Win11ISOContentsDir"] = $isoContents

            SetProgress "Modification complete" 100
            Log "install.wim modification complete. Choose an output option in Step 4."

            $sync["WPFWin11ISOOutputSection"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"
            })
        } catch {
            Log "ERROR during modification: $_"

            try {
                if (Test-Path $mountDir) {
                    $mountedImages = Get-WindowsImage -Mounted -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $mountDir }
                    if ($mountedImages) {
                        Log "Cleaning up: dismounting install.wim (discarding changes)..."
                        Dismount-WindowsImage -Path $mountDir -Discard -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            } catch { Log "Warning: could not dismount install.wim during cleanup: $_" }

            try {
                $mountedISO = Get-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue
                if ($mountedISO -and $mountedISO.Attached) {
                    Log "Cleaning up: dismounting source ISO..."
                    Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue | Out-Null
                }
            } catch { Log "Warning: could not dismount ISO during cleanup: $_" }

            try {
                if (Test-Path $workDir) {
                    Log "Cleaning up: removing temp directory $workDir..."
                    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch { Log "Warning: could not remove temp directory during cleanup: $_" }

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred during install.wim modification:`n`n$_",
                    "Modification Error", "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["Win11ISOModifying"] = $false
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value            = 0
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
                if ($sync["WPFWin11ISOOutputSection"].Visibility -ne "Visible") {
                    $sync["WPFWin11ISOSelectSection"].Visibility = "Visible"
                    $sync["WPFWin11ISOMountSection"].Visibility  = "Visible"
                    $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
                }
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}

function Invoke-WinUtilISOCheckExistingWork {
    if ($sync["Win11ISOContentsDir"] -and (Test-Path $sync["Win11ISOContentsDir"])) { return }

    # Check if ISO modification is currently in progress
    if ($sync["Win11ISOModifying"]) {
        return
    }

    $existingWorkDir = Get-Item -Path (Join-Path $env:TEMP "WinUtil_Win11ISO*") -ErrorAction SilentlyContinue |
        Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $existingWorkDir) { return }

    $isoContents = Join-Path $existingWorkDir.FullName "iso_contents"
    if (-not (Test-Path $isoContents)) { return }

    $sync["Win11ISOWorkDir"]     = $existingWorkDir.FullName
    $sync["Win11ISOContentsDir"] = $isoContents

    $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOMountSection"].Visibility  = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"

    $modified = $existingWorkDir.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    Write-Win11ISOLog "Existing working directory found: $($existingWorkDir.FullName)"
    Write-Win11ISOLog "Last modified: $modified - Skipping Steps 1-3 and resuming at Step 4."
    Write-Win11ISOLog "Click 'Clean & Reset' if you want to start over with a new ISO."

    [System.Windows.MessageBox]::Show(
        "A previous WinUtil ISO working directory was found:`n`n$($existingWorkDir.FullName)`n`n(Last modified: $modified)`n`nStep 4 (output options) has been restored so you can save the already-modified image.`n`nClick 'Clean & Reset' in Step 4 if you want to start over.",
        "Existing Work Found", "OK", "Info")
}

function Invoke-WinUtilISOCleanAndReset {
    $workDir = $sync["Win11ISOWorkDir"]

    if ($workDir -and (Test-Path $workDir)) {
        $confirm = [System.Windows.MessageBox]::Show(
            "This will delete the temporary working directory:`n`n$workDir`n`nAnd reset the interface back to the start.`n`nContinue?",
            "Clean & Reset", "YesNo", "Warning")
        if ($confirm -ne "Yes") { return }
    }

    $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $false

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync",    $sync)
    $runspace.SessionStateProxy.SetVariable("workDir", $workDir)

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
            Add-Content -Path (Join-Path $workDir "WinUtil_Win11ISO.log") -Value "[$ts] $msg" -ErrorAction SilentlyContinue
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value            = [Math]::Max($pct, 5)
            })
        }

        try {
            if ($workDir) {
                $mountDir = Join-Path $workDir "wim_mount"
                try {
                    $mountedImages = Get-WindowsImage -Mounted -ErrorAction SilentlyContinue |
                                     Where-Object { $_.Path -like "$workDir*" }
                    if ($mountedImages) {
                        foreach ($img in $mountedImages) {
                            Log "Dismounting WIM at: $($img.Path) (discarding changes)..."
                            SetProgress "Dismounting WIM image..." 3
                            Dismount-WindowsImage -Path $img.Path -Discard -ErrorAction Stop | Out-Null
                            Log "WIM dismounted successfully."
                        }
                    } elseif (Test-Path $mountDir) {
                        Log "No mounted WIM reported by Get-WindowsImage, running DISM /Cleanup-Wim as a precaution..."
                        SetProgress "Running DISM cleanup..." 3
                        & dism /English /Cleanup-Wim 2>&1 | ForEach-Object { Log $_ }
                    }
                } catch {
                    Log "Warning: could not dismount WIM cleanly, attempting DISM /Cleanup-Wim fallback: $_"
                    try { & dism /English /Cleanup-Wim 2>&1 | ForEach-Object { Log $_ } }
                    catch { Log "Warning: DISM /Cleanup-Wim also failed: $_" }
                }
            }

            if ($workDir -and (Test-Path $workDir)) {
                Log "Scanning files to delete in: $workDir"
                SetProgress "Scanning files..." 5

                $allFiles = @(Get-ChildItem -Path $workDir -File -Recurse -Force -ErrorAction SilentlyContinue)
                $allDirs  = @(Get-ChildItem -Path $workDir -Directory -Recurse -Force -ErrorAction SilentlyContinue |
                    Sort-Object { $_.FullName.Length } -Descending)
                $total   = $allFiles.Count
                $deleted = 0

                Log "Found $total files to delete."

                foreach ($f in $allFiles) {
                    try { Remove-Item -Path $f.FullName -Force -ErrorAction Stop } catch { Log "WARNING: could not delete $($f.FullName): $_" }
                    $deleted++
                    if ($deleted % 100 -eq 0 -or $deleted -eq $total) {
                        $pct = [math]::Round(($deleted / [Math]::Max($total, 1)) * 85) + 5
                        SetProgress "Deleting files in $($f.Directory.Name)... ($deleted / $total)" $pct
                    }
                }

                foreach ($d in $allDirs) {
                    try { Remove-Item -Path $d.FullName -Force -ErrorAction SilentlyContinue } catch {}
                }

                try { Remove-Item -Path $workDir -Recurse -Force -ErrorAction Stop } catch {}

                if (Test-Path $workDir) {
                    Log "WARNING: some items could not be deleted in $workDir"
                } else {
                    Log "Temp directory deleted successfully."
                }
            } else {
                Log "No temp directory found — resetting UI."
            }

            SetProgress "Resetting UI..." 95
            Log "Resetting interface..."

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["Win11ISOWorkDir"]     = $null
                $sync["Win11ISOContentsDir"] = $null
                $sync["Win11ISOImagePath"]   = $null
                $sync["Win11ISODriveLetter"] = $null
                $sync["Win11ISOWimPath"]     = $null
                $sync["Win11ISOImageInfo"]   = $null
                $sync["Win11ISOUSBDisks"]    = $null

                $sync["WPFWin11ISOPath"].Text                   = "No ISO selected..."
                $sync["WPFWin11ISOFileInfo"].Visibility          = "Collapsed"
                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
                $sync["WPFWin11ISOOptionUSB"].Visibility         = "Collapsed"
                $sync["WPFWin11ISOOutputSection"].Visibility     = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility     = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility      = "Collapsed"
                $sync["WPFWin11ISOSelectSection"].Visibility     = "Visible"
                $sync["WPFWin11ISOModifyButton"].IsEnabled       = $true
                $sync["WPFWin11ISOCleanResetButton"].IsEnabled   = $true

                $sync.progressBarTextBlock.Text    = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value            = 0

                $sync["WPFWin11ISOStatusLog"].Text   = "Ready. Please select a Windows 11 ISO to begin."
            })
        } catch {
            Log "ERROR during Clean & Reset: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value            = 0
                $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $true
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}

function Invoke-WinUtilISOExport {
    $contentsDir = $sync["Win11ISOContentsDir"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show(
            "No modified ISO content found.  Please complete Steps 1-3 first.",
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

    # Locate oscdimg.exe (Windows ADK or winget per-user install)
    $oscdimg = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
               Select-Object -First 1 -ExpandProperty FullName
    if (-not $oscdimg) {
        $oscdimg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
                   Where-Object { $_.FullName -match 'Microsoft\.OSCDIMG' } |
                   Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $oscdimg) {
        Write-Win11ISOLog "oscdimg.exe not found. Attempting to install via winget..."
        try {
            $winget = Get-Command winget -ErrorAction Stop
            $result = & $winget install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements 2>&1
            Write-Win11ISOLog "winget output: $result"
            $oscdimg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
                       Where-Object { $_.FullName -match 'Microsoft\.OSCDIMG' } |
                       Select-Object -First 1 -ExpandProperty FullName
        } catch {
            Write-Win11ISOLog "winget not available or install failed: $_"
        }

        if (-not $oscdimg) {
            Write-Win11ISOLog "oscdimg.exe still not found after install attempt."
            [System.Windows.MessageBox]::Show(
                "oscdimg.exe could not be found or installed automatically.`n`nPlease install it manually:`n  winget install -e --id Microsoft.OSCDIMG`n`nOr install the Windows ADK from:`nhttps://learn.microsoft.com/windows-hardware/get-started/adk-install",
                "oscdimg Not Found", "OK", "Warning")
            return
        }
        Write-Win11ISOLog "oscdimg.exe installed successfully."
    }

    $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync",        $sync)
    $runspace.SessionStateProxy.SetVariable("contentsDir", $contentsDir)
    $runspace.SessionStateProxy.SetVariable("outputISO",   $outputISO)
    $runspace.SessionStateProxy.SetVariable("oscdimg",     $oscdimg)

    $win11ISOLogFuncDef = "function Write-Win11ISOLog {`n" + ${function:Write-Win11ISOLog}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value            = [Math]::Max($pct, 5)
            })
        }

        try {
            Write-Win11ISOLog "Exporting to ISO: $outputISO"
            SetProgress "Building ISO..." 10

            $bootData    = "2#p0,e,b`"$contentsDir\boot\etfsboot.com`"#pEF,e,b`"$contentsDir\efi\microsoft\boot\efisys.bin`""
            $oscdimgArgs = @("-m", "-o", "-u2", "-udfver102", "-bootdata:$bootData", "-l`"CTOS_MODIFIED`"", "`"$contentsDir`"", "`"$outputISO`"")

            Write-Win11ISOLog "Running oscdimg..."

            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName               = $oscdimg
            $psi.Arguments              = $oscdimgArgs -join " "
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError  = $true
            $psi.UseShellExecute        = $false
            $psi.CreateNoWindow         = $true

            $proc = [System.Diagnostics.Process]::new()
            $proc.StartInfo = $psi
            $proc.Start() | Out-Null

            # Stream stdout line-by-line as oscdimg runs
            while (-not $proc.StandardOutput.EndOfStream) {
                $line = $proc.StandardOutput.ReadLine()
                if ($line.Trim()) { Write-Win11ISOLog $line }
            }

            $proc.WaitForExit()

            # Flush any stderr after process exits
            $stderr = $proc.StandardError.ReadToEnd()
            foreach ($line in ($stderr -split "`r?`n")) {
                if ($line.Trim()) { Write-Win11ISOLog "[stderr]$line" }
            }

            if ($proc.ExitCode -eq 0) {
                SetProgress "ISO exported" 100
                Write-Win11ISOLog "ISO exported successfully: $outputISO"
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    [System.Windows.MessageBox]::Show("ISO exported successfully!`n`n$outputISO", "Export Complete", "OK", "Info")
                })
            } else {
                Write-Win11ISOLog "oscdimg exited with code $($proc.ExitCode)."
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    [System.Windows.MessageBox]::Show(
                        "oscdimg exited with code $($proc.ExitCode).`nCheck the status log for details.",
                        "Export Error", "OK", "Error")
                })
            }
        } catch {
            Write-Win11ISOLog "ERROR during ISO export: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show("ISO export failed:`n`n$_", "Error", "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text    = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value            = 0
                $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $true
            })
        }
    }) | Out-Null

    $script.BeginInvoke() | Out-Null
}
