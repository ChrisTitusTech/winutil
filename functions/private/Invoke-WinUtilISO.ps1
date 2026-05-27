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
    $dlg = [System.Windows.Forms.OpenFileDialog]::new()
    $dlg.Title = "Select Windows 11 ISO"
    $dlg.Filter = "ISO files (*.iso)|*.iso|All files (*.*)|*.*"

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $isoPath = $dlg.FileName
    $fileSizeGB = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)

    $sync["WPFWin11ISOPath"].Text = $isoPath
    $sync["WPFWin11ISOFileInfo"].Text = "File size: $fileSizeGB GB"
    $sync["WPFWin11ISOFileInfo"].Visibility = "Visible"
    $sync["WPFWin11ISOMountSection"].Visibility = "Visible"
    $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility = "Collapsed"

    Write-Win11ISOLog "ISO selected: $isoPath ($fileSizeGB GB)"
}

function Invoke-WinUtilISOMountAndVerify {
    $isoPath = $sync["WPFWin11ISOPath"].Text

    if ([string]::IsNullOrWhiteSpace($isoPath) -or $isoPath -eq "No ISO selected...") {
        [System.Windows.MessageBox]::Show("Please select an ISO file first.", "No ISO Selected", "OK", "Warning")
        return
    }

    $sync["WPFWin11ISOMountButton"].IsEnabled = $false
    Write-Win11ISOLog "Mounting ISO: $isoPath"

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("isoPath", $isoPath)

    $win11ISOLogFuncDef = "function Write-Win11ISOLog {`n" + ${function:Write-Win11ISOLog}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value = [Math]::Max($pct, 5)
            })
        }

        try {
            SetProgress "Mounting ISO..." 10
            Mount-DiskImage -ImagePath $isoPath

            do { Start-Sleep -Milliseconds 100 } until ((Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter)

            $driveLetter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter + ":"
            Write-Win11ISOLog "Mounted at drive $driveLetter"
            SetProgress "Verifying ISO contents..." 30

            $wimPath = Join-Path $driveLetter "sources\install.wim"
            $esdPath = Join-Path $driveLetter "sources\install.esd"

            if (-not (Test-Path $wimPath) -and -not (Test-Path $esdPath)) {
                Dismount-DiskImage -ImagePath $isoPath
                Write-Win11ISOLog "ERROR: install.wim/install.esd not found — not a valid Windows ISO."
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    [System.Windows.MessageBox]::Show(
                        "This does not appear to be a valid Windows ISO.`n`ninstall.wim / install.esd was not found.",
                        "Invalid ISO", "OK", "Error")
                })
                return
            }

            $activeWim = if (Test-Path $wimPath) { $wimPath } else { $esdPath }

            SetProgress "Reading image metadata..." 55
            $imageInfo = Get-WindowsImage -ImagePath $activeWim | Select-Object ImageIndex, ImageName

            if (-not ($imageInfo | Where-Object { $_.ImageName -match "Windows 11" })) {
                Dismount-DiskImage -ImagePath $isoPath
                Write-Win11ISOLog "ERROR: No 'Windows 11' edition found in the image."
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    [System.Windows.MessageBox]::Show(
                        "No Windows 11 edition was found in this ISO.`n`nOnly official Windows 11 ISOs are supported.",
                        "Not a Windows 11 ISO", "OK", "Error")
                })
                return
            }

            $sync["Win11ISOImageInfo"] = $imageInfo
            $sync["Win11ISODriveLetter"] = $driveLetter
            $sync["Win11ISOWimPath"] = $activeWim
            $sync["Win11ISOImagePath"] = $isoPath

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOMountDriveLetter"].Text = "Mounted at: $driveLetter | Image file: $(Split-Path $activeWim -Leaf)"

                $sync["WPFWin11ISOEditionComboBox"].Items.Clear()
                foreach ($img in $imageInfo) {
                    $sync["WPFWin11ISOEditionComboBox"].Items.Add("$($img.ImageIndex): $($img.ImageName)")
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

                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Visible"
                $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
            })

            SetProgress "ISO verified" 100
            Write-Win11ISOLog "ISO verified OK. Editions found: $($imageInfo.Count)"

        } catch {
            Write-Win11ISOLog "ERROR during mount/verify: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred while mounting or verifying the ISO:`n`n$_",
                    "Error", "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0
                $sync["WPFWin11ISOMountButton"].IsEnabled = $true
            })
        }
    })

    $script.BeginInvoke()
}

function Invoke-WinUtilISOModify {
    $isoPath = $sync["Win11ISOImagePath"]
    $driveLetter = $sync["Win11ISODriveLetter"]
    $wimPath = $sync["Win11ISOWimPath"]

    if (-not $isoPath) {
        [System.Windows.MessageBox]::Show(
            "No verified ISO found. Please complete Steps 1 and 2 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    $selectedItem = $sync["WPFWin11ISOEditionComboBox"].SelectedItem
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

    $existingWorkDir = Get-Item -Path (Join-Path $env:TEMP "WinUtil_Win11ISO*") |
        Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $workDir = if ($existingWorkDir) {
        Write-Win11ISOLog "Reusing existing temp directory: $($existingWorkDir.FullName)"
        $existingWorkDir.FullName
    } else {
        Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $injectDrivers = $sync["WPFWin11ISOInjectDrivers"].IsChecked -eq $true

    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("isoPath", $isoPath)
    $runspace.SessionStateProxy.SetVariable("driveLetter", $driveLetter)
    $runspace.SessionStateProxy.SetVariable("wimPath", $wimPath)
    $runspace.SessionStateProxy.SetVariable("workDir", $workDir)
    $runspace.SessionStateProxy.SetVariable("selectedWimIndex", $selectedWimIndex)
    $runspace.SessionStateProxy.SetVariable("selectedEditionName", $selectedEditionName)
    $runspace.SessionStateProxy.SetVariable("autounattendContent", $WinUtilAutounattendXml)
    $runspace.SessionStateProxy.SetVariable("injectDrivers", $injectDrivers)

    $win11ISOLogFuncDef = "function Write-Win11ISOLog {`n" + ${function:Write-Win11ISOLog}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        function Log($msg) {
            Write-Win11ISOLog $msg
            Add-Content -Path (Join-Path $workDir "WinUtil_Win11ISO.log") -Value "[$(Get-Date -Format 'HH:mm:ss')] $msg"
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value = [Math]::Max($pct, 5)
            })
        }

        try {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
            })

            Log "Creating working directory: $workDir"
            $isoContents = Join-Path $workDir "iso_contents"
            $mountDir = Join-Path $workDir "wim_mount"
            New-Item -ItemType Directory -Path $isoContents, $mountDir -Force
            SetProgress "Copying ISO contents..." 10

            Log "Copying ISO contents from $driveLetter to $isoContents..."
            Copy-Item -Path "$driveLetter\*" -Destination $isoContents -Recurse -Force
            Log "ISO contents copied."
            SetProgress "Mounting install.wim..." 25

            $localWim = Join-Path $isoContents "sources\install.wim"
            if (-not (Test-Path $localWim)) { $localWim = Join-Path $isoContents "sources\install.esd" }
            Set-ItemProperty -Path $localWim -Name IsReadOnly -Value $false

            Log "Mounting install.wim (Index ${selectedWimIndex}: $selectedEditionName) at $mountDir..."
            Mount-WindowsImage -ImagePath $localWim -Index $selectedWimIndex -Path $mountDir
            SetProgress "Modifying install.wim..." 45

            Set-Content -Path "$isoContents\autounattend.xml" -Value $autounattendContent
            Log "Written autounattend.xml to ISO root."

            Remove-Item -Path "$isoContents\support" -Recurse -Force
            Log "Removed support folder from ISO root."

            if ($injectDrivers) {
                New-Item -Path "$Env:Temp\Driver" -ItemType Directory -Force

                Log "Injecting current system drivers (This might take a few minutes)..."
                Export-WindowsDriver -Online -Destination "$Env:Temp\Driver"
                & dism /image:$mountDir /Add-Driver /Driver:"$Env:Temp\Driver" /Recurse

                Remove-Item -Path "$Env:Temp\Driver" -Recurse -Force
            }

            SetProgress "Cleaning up component store (WinSxS) This might take several minutes..." 56
            Log "Running DISM component store cleanup (/ResetBase) This might take a few minutes..."
            & dism /English "/image:$mountDir" /Cleanup-Image /StartComponentCleanup /ResetBase
            Log "Component store cleanup complete."

            SetProgress "Saving modified install.wim..." 65
            Log "Dismounting and saving install.wim. This will take several minutes..."
            Dismount-WindowsImage -Path $mountDir -Save
            Log "install.wim saved."

            SetProgress "Removing unused editions from install.wim..." 70
            Log "Exporting edition '$selectedEditionName' (Index $selectedWimIndex) to a single-edition install.wim..."
            $exportWim = Join-Path $isoContents "sources\install_export.wim"
            Export-WindowsImage -SourceImagePath $localWim -SourceIndex $selectedWimIndex -DestinationImagePath $exportWim
            Remove-Item -Path $localWim -Force
            Rename-Item -Path $exportWim -NewName "install.wim" -Force
            $localWim = Join-Path $isoContents "sources\install.wim"
            Log "Unused editions removed. install.wim now contains only '$selectedEditionName'."

            SetProgress "Dismounting source ISO..." 80
            Log "Dismounting original ISO..."
            Dismount-DiskImage -ImagePath $isoPath

            $sync["Win11ISOWorkDir"] = $workDir
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
                    $mountedImages = Get-WindowsImage -Mounted | Where-Object { $_.Path -eq $mountDir }
                    if ($mountedImages) {
                        Log "Cleaning up: dismounting install.wim (discarding changes)..."
                        Dismount-WindowsImage -Path $mountDir -Discard
                    }
                }
            } catch { Log "Warning: could not dismount install.wim during cleanup: $_" }

            try {
                $mountedISO = Get-DiskImage -ImagePath $isoPath
                if ($mountedISO -and $mountedISO.Attached) {
                    Log "Cleaning up: dismounting source ISO..."
                    Dismount-DiskImage -ImagePath $isoPath
                }
            } catch { Log "Warning: could not dismount ISO during cleanup: $_" }

            Remove-Item -Path $workDir -Recurse -Force

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred during install.wim modification:`n`n$_",
                    "Modification Error", "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["Win11ISOModifying"] = $false
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
                if ($sync["WPFWin11ISOOutputSection"].Visibility -ne "Visible") {
                    $sync["WPFWin11ISOSelectSection"].Visibility = "Visible"
                    $sync["WPFWin11ISOMountSection"].Visibility = "Visible"
                    $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
                }
            })
        }
    })

    $script.BeginInvoke()
}

function Invoke-WinUtilISOCheckExistingWork {
    if ($sync["Win11ISOContentsDir"] -and (Test-Path $sync["Win11ISOContentsDir"])) { return }
    if ($sync["Win11ISOModifying"]) { return }

    $existingWorkDir = Get-Item -Path (Join-Path $env:TEMP "WinUtil_Win11ISO*") |
        Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $existingWorkDir) { return }

    $isoContents = Join-Path $existingWorkDir.FullName "iso_contents"
    if (-not (Test-Path $isoContents)) { return }

    $sync["Win11ISOWorkDir"] = $existingWorkDir.FullName
    $sync["Win11ISOContentsDir"] = $isoContents

    $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"

    $modified = $existingWorkDir.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    Write-Win11ISOLog "Existing working directory found: $($existingWorkDir.FullName)"
    Write-Win11ISOLog "Last modified: $modified - Skipping Steps 1-3 and resuming at Step 4."
    Write-Win11ISOLog "Click 'Clean And Reset' if you want to start over with a new ISO."

    [System.Windows.MessageBox]::Show(
        "A previous WinUtil ISO working directory was found:`n`n$($existingWorkDir.FullName)`n`n(Last modified: $modified)`n`nStep 4 (output options) has been restored so you can save the already-modified image.`n`nClick 'Clean And Reset' in Step 4 if you want to start over.",
        "Existing Work Found", "OK", "Info")
}

function Invoke-WinUtilISOCleanAndReset {
    $workDir = $sync["Win11ISOWorkDir"]

    if ($workDir -and (Test-Path $workDir)) {
        $confirm = [System.Windows.MessageBox]::Show(
            "This will delete the temporary working directory:`n`n$workDir`n`nAnd reset the interface back to the start.`n`nContinue?",
            "Clean And Reset", "YesNo", "Warning")
        if ($confirm -ne "Yes") { return }
    }

    $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $false

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("workDir", $workDir)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({

            function SetProgress($label, $pct) {
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    $sync.progressBarTextBlock.Text = $label
                    $sync.progressBarTextBlock.ToolTip = $label
                    $sync.ProgressBar.Value = [Math]::Max($pct, 5)
                })
            }
        try {
            if ($workDir -and (Test-Path $workDir)) {
                SetProgress "Removing files..." 75
                Remove-Item -Path $workDir -Recurse -Force
            }

            SetProgress "Resetting UI..." 95

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["Win11ISOWorkDir"] = $null
                $sync["Win11ISOContentsDir"] = $null
                $sync["Win11ISOImagePath"] = $null
                $sync["Win11ISODriveLetter"] = $null
                $sync["Win11ISOWimPath"] = $null
                $sync["Win11ISOImageInfo"] = $null
                $sync["Win11ISOUSBDisks"] = $null

                $sync["WPFWin11ISOPath"].Text = "No ISO selected..."
                $sync["WPFWin11ISOFileInfo"].Visibility = "Collapsed"
                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
                $sync["WPFWin11ISOOptionUSB"].Visibility = "Collapsed"
                $sync["WPFWin11ISOOutputSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOSelectSection"].Visibility = "Visible"
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
                $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $true

                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0

                $sync["WPFWin11ISOStatusLog"].Text = "Ready. Please select a Windows 11 ISO to begin."
            })
        } catch {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0
                $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $true
            })
        }
    })

    $script.BeginInvoke()
}

function Invoke-WinUtilISOExport {
    $contentsDir = $sync["Win11ISOContentsDir"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show(
            "No modified ISO content found.  Please complete Steps 1-3 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    $dlg = [System.Windows.Forms.SaveFileDialog]::new()
    $dlg.Title = "Save Modified Windows 11 ISO"
    $dlg.Filter = "ISO files (*.iso)|*.iso"
    $dlg.FileName = "Win11_Modified_$(Get-Date -Format 'yyyyMMdd').iso"
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $outputISO = $dlg.FileName

    Invoke-WebRequest -Uri https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe -OutFile "$Env:Temp\oscdimg.exe"
    $oscdimg = "$Env:Temp\oscdimg.exe"

    $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("contentsDir", $contentsDir)
    $runspace.SessionStateProxy.SetVariable("outputISO", $outputISO)
    $runspace.SessionStateProxy.SetVariable("oscdimg", $oscdimg)

    $win11ISOLogFuncDef = "function Write-Win11ISOLog {`n" + ${function:Write-Win11ISOLog}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = $label
                $sync.progressBarTextBlock.ToolTip = $label
                $sync.ProgressBar.Value = [Math]::Max($pct, 5)
            })
        }

        try {
            Write-Win11ISOLog "Exporting to ISO: $outputISO"
            SetProgress "Building ISO..." 10

            $bootData = "2#p0,e,b`"$contentsDir\boot\etfsboot.com`"#pEF,e,b`"$contentsDir\efi\microsoft\boot\efisys.bin`""
            $oscdimgArgs = @("-m", "-o", "-h", "-u2", "-udfver102", "-bootdata:$bootData", "-l`"CTOS_MODIFIED`"", "`"$contentsDir`"", "`"$outputISO`"")

            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName = $oscdimg
            $psi.Arguments = $oscdimgArgs -join " "
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::new()
            $proc.StartInfo = $psi
            $proc.Start()

            Write-Win11ISOLog "Running oscdimg..."
            $proc.WaitForExit()

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
                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0
                $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $true
            })
        }
    })

    $script.BeginInvoke()
}
