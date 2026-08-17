function Write-WinUtilISOLog {
    param([string]$Message)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $logLine = "[$ts] $Message"
    $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
        $current = $sync["WPFWin11ISOStatusLog"].Text
        if ($current -eq (Get-WinUtilText "Ready. Please select a Windows 11 ISO to begin.")) {
            $sync["WPFWin11ISOStatusLog"].Text = $logLine
        } else {
            $sync["WPFWin11ISOStatusLog"].Text += "`n$logLine"
        }
        $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
        $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
    })
}

function Invoke-WinUtilISOBrowse {
    Add-Type -AssemblyName System.Windows.Forms

    $dlg = [System.Windows.Forms.OpenFileDialog]::new()
    $dlg.Title            = Get-WinUtilText "Select Windows 11 ISO"
    $dlg.Filter           = (Get-WinUtilText "ISO files (*.iso)|*.iso|All files (*.*)|*.*")
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $isoPath    = $dlg.FileName
    $fileSizeGB = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)

    $sync["WPFWin11ISOPath"].Text           = $isoPath
    $sync["WPFWin11ISOFileInfo"].Text       = Get-WinUtilFormattedText -Template "File size: {0} GB" -FormatArgs @($fileSizeGB)
    $sync["WPFWin11ISOFileInfo"].Visibility = "Visible"
    $sync["WPFWin11ISOMountSection"].Visibility       = "Visible"
    $sync["WPFWin11ISOVerifyResultPanel"].Visibility  = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility      = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility      = "Collapsed"

    Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "ISO selected: {0}  ({1} GB)" -FormatArgs @($isoPath, $fileSizeGB))
}

function Invoke-WinUtilISOMountAndVerify {
    $isoPath = $sync["WPFWin11ISOPath"].Text

    if ([string]::IsNullOrWhiteSpace($isoPath) -or $isoPath -eq (Get-WinUtilText "No ISO selected...")) {
        [System.Windows.MessageBox]::Show((Get-WinUtilText "Please select an ISO file first."), (Get-WinUtilText "No ISO Selected"), "OK", "Warning")
        return
    }

    Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "Mounting ISO: {0}" -FormatArgs @($isoPath))
    Set-WinUtilTweaksProgressIndicator -Visible $true -Label (Get-WinUtilText "Mounting ISO...") -Percent 10
    $sync["WPFWin11ISOBrowseButton"].IsEnabled = $false
    $sync["WPFWin11ISOMountButton"].IsEnabled = $false
    $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
    $sync["Win11ISOProcessRunning"] = $true

    Invoke-WPFRunspace -ParameterList @(,('isoPath', $isoPath)) -ScriptBlock {
        param($isoPath)

        try {
            Mount-DiskImage -ImagePath $isoPath

            do {
                Start-Sleep -Milliseconds 500
            } until ((Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter)

            $driveLetter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter + ":"
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "Mounted at drive {0}" -FormatArgs @($driveLetter))

            Set-WinUtilTweaksProgressIndicator -Visible $true -Label (Get-WinUtilText "Verifying ISO contents...") -Percent 30

            $wimPath = Join-Path $driveLetter "sources\install.wim"
            $esdPath = Join-Path $driveLetter "sources\install.esd"

            if (-not (Test-Path $wimPath) -and -not (Test-Path $esdPath)) {
                Dismount-DiskImage -ImagePath $isoPath
                Write-WinUtilISOLog (Get-WinUtilText "ERROR: install.wim/install.esd not found - not a valid Windows ISO.")
                Invoke-WPFUIThread {
                    [System.Windows.MessageBox]::Show(
                        (Get-WinUtilText "This does not appear to be a valid Windows ISO.`n`ninstall.wim / install.esd was not found."),
                        (Get-WinUtilText "Invalid ISO"), "OK", "Error")
                }
                return
            }

            $activeWim = if (Test-Path $wimPath) { $wimPath } else { $esdPath }

            Set-WinUtilTweaksProgressIndicator -Visible $true -Label (Get-WinUtilText "Reading image metadata...") -Percent 55
            $imageInfo = Get-WindowsImage -ImagePath $activeWim | Select-Object ImageIndex, ImageName

            if (-not ($imageInfo | Where-Object { $_.ImageName -match "Windows 11" })) {
                Dismount-DiskImage -ImagePath $isoPath
                Write-WinUtilISOLog (Get-WinUtilText "ERROR: No 'Windows 11' edition found in the image.")
                Invoke-WPFUIThread {
                    [System.Windows.MessageBox]::Show(
                        (Get-WinUtilText "No Windows 11 edition was found in this ISO.`n`nOnly official Windows 11 ISOs are supported."),
                        (Get-WinUtilText "Not a Windows 11 ISO"), "OK", "Error")
                }
                return
            }

            $sync["Win11ISOImageInfo"] = $imageInfo
            $sync["Win11ISODriveLetter"] = $driveLetter
            $sync["Win11ISOWimPath"]     = $activeWim
            $sync["Win11ISOImagePath"]   = $isoPath

            Invoke-WPFUIThread {
                $sync["WPFWin11ISOMountDriveLetter"].Text = Get-WinUtilFormattedText -Template "Mounted at: {0}   |   Image file: {1}" -FormatArgs @($driveLetter, (Split-Path $activeWim -Leaf))
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
                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Visible"
                $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
            }

            Set-WinUtilTweaksProgressIndicator -Visible $true -Label (Get-WinUtilText "ISO verified") -Percent 100
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "ISO verified OK.  Editions found: {0}" -FormatArgs @($imageInfo.Count))
        } catch {
            $errorMessage = $_
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "ERROR during mount/verify: {0}" -FormatArgs @($errorMessage))
            Invoke-WPFUIThread {
                [System.Windows.MessageBox]::Show(
                    (Get-WinUtilFormattedText -Template "An error occurred while mounting or verifying the ISO:`n`n{0}" -FormatArgs @($errorMessage)),
                    (Get-WinUtilText "Error"), "OK", "Error")
            }
        } finally {
            Start-Sleep -Milliseconds 800
            Set-WinUtilTweaksProgressIndicator -Visible $false
            Invoke-WPFUIThread {
                $sync["WPFWin11ISOBrowseButton"].IsEnabled = $true
                $sync["WPFWin11ISOMountButton"].IsEnabled = $true
                $sync["Win11ISOProcessRunning"] = $false
            }
        }
    }
}

function Invoke-WinUtilISOModify {
    $isoPath     = $sync["Win11ISOImagePath"]
    $driveLetter = $sync["Win11ISODriveLetter"]
    $wimPath     = $sync["Win11ISOWimPath"]

    if (-not $isoPath) {
        [System.Windows.MessageBox]::Show(
            (Get-WinUtilText "No verified ISO found. Please complete Steps 1 and 2 first."),
            (Get-WinUtilText "Not Ready"), "OK", "Warning")
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
    Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "Selected edition: {0} (Index {1})" -FormatArgs @($selectedEditionName, $selectedWimIndex))

    $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
    $sync["Win11ISOModifying"] = $true
    $sync["Win11ISOProcessRunning"] = $true

    $workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    if (Test-Path $workDir) {
        $workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(([guid]::NewGuid()).ToString('N').Substring(0, 8))"
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
    $win11ISOLogFuncDef = "function Write-WinUtilISOLog {`n"     + ${function:Write-WinUtilISOLog}.ToString()     + "`n}"
    $i18nFuncDef        = "function Get-WinUtilText {`n"          + ${function:Get-WinUtilText}.ToString()          + "`n}function Get-WinUtilFormattedText {`n" + ${function:Get-WinUtilFormattedText}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("isoScriptFuncDef",   $isoScriptFuncDef)
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)
    $runspace.SessionStateProxy.SetVariable("i18nFuncDef",        $i18nFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($isoScriptFuncDef))
        . ([scriptblock]::Create($win11ISOLogFuncDef))
        . ([scriptblock]::Create($i18nFuncDef))

        function Log($msg) {
            $ts = (Get-Date).ToString("HH:mm:ss")
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text += "`n[$ts] $msg"
                $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
            Add-Content -Path (Join-Path $workDir "WinUtil_Win11ISO.log") -Value "[$ts] $msg"
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFTweaksProgressBar"].Visibility = "Visible"
                $sync["WPFTweaksProgressLabel"].Text      = $label
                $sync["WPFTweaksProgressLabel"].ToolTip   = $label
                $sync["WPFTweaksProgressValue"].Value     = [Math]::Max($pct, 5)
            })
        }

        function Get-WinUtilEditionIdFromName {
            param([string]$EditionName)

            $normalizedName = ($EditionName -replace '^Windows\s+11\s+', '').Trim()
            switch -Regex ($normalizedName) {
                '^Home Single Language$'      { return 'CoreSingleLanguage' }
                '^Home N$'                    { return 'CoreN' }
                '^Home$'                      { return 'Core' }
                '^Pro for Workstations N$'    { return 'ProfessionalWorkstationN' }
                '^Pro for Workstations$'      { return 'ProfessionalWorkstation' }
                '^Pro Education N$'           { return 'ProfessionalEducationN' }
                '^Pro Education$'             { return 'ProfessionalEducation' }
                '^Pro N$'                     { return 'ProfessionalN' }
                '^Pro$'                       { return 'Professional' }
                '^Education N$'               { return 'EducationN' }
                '^Education$'                 { return 'Education' }
                '^Enterprise LTSC N$'         { return 'EnterpriseSN' }
                '^Enterprise LTSC$'           { return 'EnterpriseS' }
                '^Enterprise N$'              { return 'EnterpriseN' }
                '^Enterprise$'                { return 'Enterprise' }
                default                       { return '' }
            }
        }

        try {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility  = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
            })

            Log (Get-WinUtilFormattedText -Template "Creating working directory: {0}" -FormatArgs @($workDir))
            $isoContents = Join-Path $workDir "iso_contents"
            New-Item -ItemType Directory -Path $isoContents -Force
            SetProgress (Get-WinUtilText "Copying ISO contents...") 10

            Log (Get-WinUtilFormattedText -Template "Copying ISO contents from {0} to {1}..." -FormatArgs @($driveLetter, $isoContents))
            & robocopy $driveLetter $isoContents /E /NFL /NDL /NJH /NJS
            Log (Get-WinUtilText "ISO contents copied.")
            SetProgress (Get-WinUtilText "Preparing setup media...") 25

            $sourceImageFileName = Split-Path $wimPath -Leaf
            $localWim = Join-Path $isoContents "sources\$sourceImageFileName"
            if (-not (Test-Path $localWim)) {
                throw "Copied ISO image file not found: sources\$sourceImageFileName"
            }
            $selectedEditionId = Get-WinUtilEditionIdFromName -EditionName $selectedEditionName

            Log (Get-WinUtilText "Writing autounattend.xml and edition selection...")
            Invoke-WinUtilISOScript -ISOContentsDir $isoContents -AutoUnattendXml $autounattendContent -InjectCurrentSystemDrivers $injectDrivers -InstallImagePath $localWim -InstallImageIndex $selectedWimIndex -InstallEditionId $selectedEditionId -Log { param($m) Log $m }

            SetProgress (Get-WinUtilText "Preserving install image...") 70
            if ($injectDrivers) {
                Log (Get-WinUtilFormattedText -Template "Added current-system drivers to {0} index {1} with one mount and commit." -FormatArgs @($sourceImageFileName, $selectedWimIndex))
            } else {
                Log (Get-WinUtilFormattedText -Template "Preserved the original {0} without mounting, exporting, or modifying it." -FormatArgs @($sourceImageFileName))
            }

            SetProgress (Get-WinUtilText "Dismounting source ISO...") 80
            Log (Get-WinUtilText "Dismounting original ISO...")
            Dismount-DiskImage -ImagePath $isoPath

            $sync["Win11ISOWorkDir"]     = $workDir
            $sync["Win11ISOContentsDir"] = $isoContents

            SetProgress (Get-WinUtilText "Modification complete") 100
            Log (Get-WinUtilText "install.wim modification complete. Choose an output option in Step 4.")

            $sync["WPFWin11ISOOutputSection"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"
            })
        } catch {
            Log (Get-WinUtilFormattedText -Template "ERROR during modification: {0}" -FormatArgs @($_))

            try {
                $mountedISO = Get-DiskImage -ImagePath $isoPath
                if ($mountedISO -and $mountedISO.Attached) {
                    Log (Get-WinUtilText "Cleaning up: dismounting source ISO...")
                    Dismount-DiskImage -ImagePath $isoPath
                }
            } catch { Log (Get-WinUtilFormattedText -Template "Warning: could not dismount ISO during cleanup: {0}" -FormatArgs @($_)) }

            try {
                if (Test-Path $workDir) {
                    Log (Get-WinUtilFormattedText -Template "Cleaning up: removing temp directory {0}..." -FormatArgs @($workDir))
                    Remove-Item -Path $workDir -Recurse -Force
                }
            } catch { Log (Get-WinUtilFormattedText -Template "Warning: could not remove temp directory during cleanup: {0}" -FormatArgs @($_)) }

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    (Get-WinUtilFormattedText -Template "An error occurred during install.wim modification:`n`n{0}" -FormatArgs @($_)),
                    (Get-WinUtilText "Modification Error"), "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["Win11ISOModifying"] = $false
            $sync["Win11ISOProcessRunning"] = $false
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFTweaksProgressBar"].Visibility = "Collapsed"
                $sync["WPFTweaksProgressLabel"].Text      = ""
                $sync["WPFTweaksProgressLabel"].ToolTip   = ""
                $sync["WPFTweaksProgressValue"].Value     = 0
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
                if ($sync["WPFWin11ISOOutputSection"].Visibility -ne "Visible") {
                    $sync["WPFWin11ISOSelectSection"].Visibility = "Visible"
                    $sync["WPFWin11ISOMountSection"].Visibility  = "Visible"
                    $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
                }
            })
        }
    })

    $script.BeginInvoke()
}

function Invoke-WinUtilISOCheckExistingWork {
    if ($sync["Win11ISOContentsDir"] -and (Test-Path $sync["Win11ISOContentsDir"])) { return }

    # Check if ISO modification is currently in progress
    if ($sync["Win11ISOModifying"]) {
        return
    }

    $existingWorkDir = Get-Item -Path (Join-Path $env:TEMP "WinUtil_Win11ISO*") |
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
    Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "Existing working directory found: {0}" -FormatArgs @($existingWorkDir.FullName))
    Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "Last modified: {0} - Skipping Steps 1-3 and resuming at Step 4." -FormatArgs @($modified))
    Write-WinUtilISOLog (Get-WinUtilText "Click 'Clean & Reset' if you want to start over with a new ISO.")

    [System.Windows.MessageBox]::Show(
        (Get-WinUtilFormattedText -Template "A previous WinUtil ISO working directory was found:`n`n{0}`n`n(Last modified: {1})`n`nStep 4 (output options) has been restored so you can save the already-modified image.`n`nClick 'Clean & Reset' in Step 4 if you want to start over." -FormatArgs @($existingWorkDir.FullName, $modified)),
        (Get-WinUtilText "Existing Work Found"), "OK", "Info")
}

function Invoke-WinUtilISOCleanAndReset {
    $workDir = $sync["Win11ISOWorkDir"]

    if ($workDir -and (Test-Path $workDir)) {
        $confirm = [System.Windows.MessageBox]::Show(
            (Get-WinUtilFormattedText -Template "This will delete the temporary working directory:`n`n{0}`n`nAnd reset the interface back to the start.`n`nContinue?" -FormatArgs @($workDir)),
            (Get-WinUtilText "Clean & Reset"), "YesNo", "Warning")
        if ($confirm -ne "Yes") { return }
    }

    $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $false
    $sync["Win11ISOProcessRunning"] = $true

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync",    $sync)
    $runspace.SessionStateProxy.SetVariable("workDir", $workDir)
    $i18nFuncDef = "function Get-WinUtilText {`n" + ${function:Get-WinUtilText}.ToString() + "`n}function Get-WinUtilFormattedText {`n" + ${function:Get-WinUtilFormattedText}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("i18nFuncDef", $i18nFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($i18nFuncDef))

        function Log($msg) {
            $ts = (Get-Date).ToString("HH:mm:ss")
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text += "`n[$ts] $msg"
                $sync["WPFWin11ISOStatusLog"].CaretIndex = $sync["WPFWin11ISOStatusLog"].Text.Length
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })
            Add-Content -Path (Join-Path $workDir "WinUtil_Win11ISO.log") -Value "[$ts] $msg"
        }

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFTweaksProgressBar"].Visibility = "Visible"
                $sync["WPFTweaksProgressLabel"].Text      = $label
                $sync["WPFTweaksProgressLabel"].ToolTip   = $label
                $sync["WPFTweaksProgressValue"].Value     = [Math]::Max($pct, 5)
            })
        }

        try {
            if ($workDir) {
                $mountDir = Join-Path $workDir "wim_mount"
                try {
                    $mountedImages = Get-WindowsImage -Mounted |
                                     Where-Object { $_.Path -like "$workDir*" }
                    if ($mountedImages) {
                        foreach ($img in $mountedImages) {
                            Log (Get-WinUtilFormattedText -Template "Dismounting WIM at: {0} (discarding changes)..." -FormatArgs @($img.Path))
                            SetProgress (Get-WinUtilText "Dismounting WIM image...") 3
                            Dismount-WindowsImage -Path $img.Path -Discard
                            Log (Get-WinUtilText "WIM dismounted successfully.")
                        }
                    } elseif (Test-Path $mountDir) {
                        Log (Get-WinUtilText "No mounted WIM reported by Get-WindowsImage. Running DISM /Cleanup-Wim as a precaution...")
                        SetProgress (Get-WinUtilText "Running DISM cleanup...") 3
                        & dism /English /Cleanup-Wim | ForEach-Object { Log $_ }
                    }
                } catch {
                    Log (Get-WinUtilFormattedText -Template "Warning: could not dismount WIM cleanly. Attempting DISM /Cleanup-Wim fallback: {0}" -FormatArgs @($_))
                    try { & dism /English /Cleanup-Wim | ForEach-Object { Log $_ } }
                    catch { Log (Get-WinUtilFormattedText -Template "Warning: DISM /Cleanup-Wim also failed: {0}" -FormatArgs @($_)) }
                }
            }

            if ($workDir -and (Test-Path $workDir)) {
                Log (Get-WinUtilFormattedText -Template "Scanning files to delete in: {0}" -FormatArgs @($workDir))
                SetProgress (Get-WinUtilText "Scanning files...") 5

                $allFiles = @(Get-ChildItem -Path $workDir -File -Recurse -Force)
                $allDirs  = @(Get-ChildItem -Path $workDir -Directory -Recurse -Force |
                    Sort-Object { $_.FullName.Length } -Descending)
                $total   = $allFiles.Count
                $deleted = 0

                Log (Get-WinUtilFormattedText -Template "Found {0} files to delete." -FormatArgs @($total))

                foreach ($f in $allFiles) {
                    try { Remove-Item -Path $f.FullName -Force } catch { Log (Get-WinUtilFormattedText -Template "WARNING: could not delete {0}: {1}" -FormatArgs @($f.FullName, $_)) }
                    $deleted++
                    if ($deleted % 100 -eq 0 -or $deleted -eq $total) {
                        $pct = [math]::Round(($deleted / [Math]::Max($total, 1)) * 85) + 5
                        SetProgress (Get-WinUtilFormattedText -Template "Deleting files in {0}... ({1} / {2})" -FormatArgs @($f.Directory.Name, $deleted, $total)) $pct
                    }
                }

                foreach ($d in $allDirs) {
                    try { Remove-Item -Path $d.FullName -Force } catch { Log (Get-WinUtilFormattedText -Template "WARNING: could not delete {0}: {1}" -FormatArgs @($d.FullName, $_)) }
                }

                try { Remove-Item -Path $workDir -Recurse -Force } catch { Log (Get-WinUtilFormattedText -Template "WARNING: could not delete temp directory {0}: {1}" -FormatArgs @($workDir, $_)) }

                if (Test-Path $workDir) {
                    Log (Get-WinUtilFormattedText -Template "WARNING: some items could not be deleted in {0}" -FormatArgs @($workDir))
                } else {
                    Log (Get-WinUtilText "Temp directory deleted successfully.")
                }
            } else {
                Log (Get-WinUtilText "No temp directory found - resetting UI.")
            }

            SetProgress (Get-WinUtilText "Resetting UI...") 95
            Log (Get-WinUtilText "Resetting interface...")

            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["Win11ISOWorkDir"]     = $null
                $sync["Win11ISOContentsDir"] = $null
                $sync["Win11ISOImagePath"]   = $null
                $sync["Win11ISODriveLetter"] = $null
                $sync["Win11ISOWimPath"]     = $null
                $sync["Win11ISOImageInfo"]   = $null
                $sync["Win11ISOUSBDisks"]    = $null

                $sync["WPFWin11ISOPath"].Text                   = Get-WinUtilText "No ISO selected..."
                $sync["WPFWin11ISOFileInfo"].Visibility          = "Collapsed"
                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
                $sync["WPFWin11ISOOptionUSB"].Visibility         = "Collapsed"
                $sync["WPFWin11ISOOutputSection"].Visibility     = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility     = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility      = "Collapsed"
                $sync["WPFWin11ISOSelectSection"].Visibility     = "Visible"
                $sync["WPFWin11ISOModifyButton"].IsEnabled       = $true
                $sync["WPFWin11ISOCleanResetButton"].IsEnabled   = $true

                $sync["WPFTweaksProgressBar"].Visibility = "Collapsed"
                $sync["WPFTweaksProgressLabel"].Text      = ""
                $sync["WPFTweaksProgressLabel"].ToolTip   = ""
                $sync["WPFTweaksProgressValue"].Value     = 0

                $sync["WPFWin11ISOStatusLog"].Text   = Get-WinUtilText "Ready. Please select a Windows 11 ISO to begin."
            })
        } catch {
            Log (Get-WinUtilFormattedText -Template "ERROR during Clean & Reset: {0}" -FormatArgs @($_))
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFTweaksProgressBar"].Visibility = "Collapsed"
                $sync["WPFTweaksProgressLabel"].Text      = ""
                $sync["WPFTweaksProgressLabel"].ToolTip   = ""
                $sync["WPFTweaksProgressValue"].Value     = 0
                $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $true
            })
        } finally {
            $sync["Win11ISOProcessRunning"] = $false
        }
    })

    $script.BeginInvoke()
}

function Invoke-WinUtilISOExport {
    $contentsDir = $sync["Win11ISOContentsDir"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show(
            (Get-WinUtilText "No modified ISO content found. Please complete Steps 1-3 first."),
            (Get-WinUtilText "Not Ready"), "OK", "Warning")
        return
    }

    Add-Type -AssemblyName System.Windows.Forms

    $dlg = [System.Windows.Forms.SaveFileDialog]::new()
    $dlg.Title            = Get-WinUtilText "Save Modified Windows 11 ISO"
    $dlg.Filter           = Get-WinUtilText "ISO files (*.iso)|*.iso"
    $dlg.FileName         = "Win11_Modified_$(Get-Date -Format 'yyyyMMdd').iso"
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $outputISO = $dlg.FileName

    # Locate oscdimg.exe (Windows ADK or winget per-user install)
    $oscdimg = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "oscdimg.exe" |
               Select-Object -First 1 -ExpandProperty FullName
    if (-not $oscdimg) {
        $oscdimg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "oscdimg.exe" |
                   Where-Object { $_.FullName -match 'Microsoft\.OSCDIMG' } |
                   Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $oscdimg) {
        Write-WinUtilISOLog (Get-WinUtilText "oscdimg.exe not found. Attempting to install via winget...")
        try {
            # First ensure winget is installed and operational
            Install-WinUtilWinget

            $winget = Get-Command winget
            $result = & $winget install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "winget output: {0}" -FormatArgs @($result))
            $oscdimg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "oscdimg.exe" |
                       Where-Object { $_.FullName -match 'Microsoft\.OSCDIMG' } |
                       Select-Object -First 1 -ExpandProperty FullName
        } catch {
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "winget not available or install failed: {0}" -FormatArgs @($_))
        }

        if (-not $oscdimg) {
            Write-WinUtilISOLog (Get-WinUtilText "oscdimg.exe still not found after install attempt.")
            [System.Windows.MessageBox]::Show(
                (Get-WinUtilText "oscdimg.exe could not be found or installed automatically.`n`nPlease install it manually:`n  winget install -e --id Microsoft.OSCDIMG`n`nOr install the Windows ADK from:`nhttps://learn.microsoft.com/windows-hardware/get-started/adk-install"),
                (Get-WinUtilText "oscdimg Not Found"), "OK", "Warning")
            return
        }
        Write-WinUtilISOLog (Get-WinUtilText "oscdimg.exe installed successfully.")
    }

    $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false
    $sync["Win11ISOProcessRunning"] = $true

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions  = "ReuseThread"
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync",        $sync)
    $runspace.SessionStateProxy.SetVariable("contentsDir", $contentsDir)
    $runspace.SessionStateProxy.SetVariable("outputISO",   $outputISO)
    $runspace.SessionStateProxy.SetVariable("oscdimg",     $oscdimg)

    $win11ISOLogFuncDef = "function Write-WinUtilISOLog {`n" + ${function:Write-WinUtilISOLog}.ToString() + "`n}"
    $i18nFuncDef        = "function Get-WinUtilText {`n"      + ${function:Get-WinUtilText}.ToString()          + "`n}function Get-WinUtilFormattedText {`n" + ${function:Get-WinUtilFormattedText}.ToString() + "`n}"
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef", $win11ISOLogFuncDef)
    $runspace.SessionStateProxy.SetVariable("i18nFuncDef",        $i18nFuncDef)

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript({
        . ([scriptblock]::Create($win11ISOLogFuncDef))
        . ([scriptblock]::Create($i18nFuncDef))

        function SetProgress($label, $pct) {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFTweaksProgressBar"].Visibility = "Visible"
                $sync["WPFTweaksProgressLabel"].Text      = $label
                $sync["WPFTweaksProgressLabel"].ToolTip   = $label
                $sync["WPFTweaksProgressValue"].Value     = [Math]::Max($pct, 5)
            })
        }

        try {
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "Exporting to ISO: {0}" -FormatArgs @($outputISO))
            SetProgress (Get-WinUtilText "Building ISO...") 10

            $bootData    = "2#p0,e,b`"$contentsDir\boot\etfsboot.com`"#pEF,e,b`"$contentsDir\efi\microsoft\boot\efisys.bin`""
            $oscdimgArgs = @("-m", "-o", "-u2", "-udfver102", "-bootdata:$bootData", "-l`"CTOS_MODIFIED`"", "`"$contentsDir`"", "`"$outputISO`"")

            Write-WinUtilISOLog (Get-WinUtilText "Running oscdimg...")

            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName               = $oscdimg
            $psi.Arguments              = $oscdimgArgs -join " "
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError  = $true
            $psi.UseShellExecute        = $false
            $psi.CreateNoWindow         = $true

            $proc = [System.Diagnostics.Process]::new()
            $proc.StartInfo = $psi
            $proc.Start()

            # Stream stdout line-by-line as oscdimg runs
            while (-not $proc.StandardOutput.EndOfStream) {
                $line = $proc.StandardOutput.ReadLine()
                if ($line.Trim()) { Write-WinUtilISOLog $line }
            }

            $proc.WaitForExit()

            # Flush any stderr after process exits
            $stderr = $proc.StandardError.ReadToEnd()
            foreach ($line in ($stderr -split "`r?`n")) {
                if ($line.Trim()) { Write-WinUtilISOLog "[stderr]$line" }
            }

            if ($proc.ExitCode -eq 0) {
                SetProgress (Get-WinUtilText "ISO exported") 100
                Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "ISO exported successfully: {0}" -FormatArgs @($outputISO))
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    [System.Windows.MessageBox]::Show((Get-WinUtilFormattedText -Template "ISO exported successfully!`n`n{0}" -FormatArgs @($outputISO)), (Get-WinUtilText "Export Complete"), "OK", "Info")
                })
            } else {
                Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "oscdimg exited with code {0}." -FormatArgs @($proc.ExitCode))
                $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                    [System.Windows.MessageBox]::Show(
                        (Get-WinUtilFormattedText -Template "oscdimg exited with code {0}.`nCheck the status log for details." -FormatArgs @($proc.ExitCode)),
                        (Get-WinUtilText "Export Error"), "OK", "Error")
                })
            }
        } catch {
            Write-WinUtilISOLog (Get-WinUtilFormattedText -Template "ERROR during ISO export: {0}" -FormatArgs @($_))
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show((Get-WinUtilFormattedText -Template "ISO export failed:`n`n{0}" -FormatArgs @($_)), (Get-WinUtilText "Error"), "OK", "Error")
            })
        } finally {
            Start-Sleep -Milliseconds 800
            $sync["Win11ISOProcessRunning"] = $false
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFTweaksProgressBar"].Visibility = "Collapsed"
                $sync["WPFTweaksProgressLabel"].Text      = ""
                $sync["WPFTweaksProgressLabel"].ToolTip   = ""
                $sync["WPFTweaksProgressValue"].Value     = 0
                $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $true
            })
        }
    })

    $script.BeginInvoke()
}
