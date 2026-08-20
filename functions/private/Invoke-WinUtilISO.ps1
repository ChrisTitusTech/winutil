function Invoke-WinUtilRobocopy {
    <#
        .SYNOPSIS
            Runs robocopy and fails the job when files were not copied

        .DESCRIPTION
            robocopy reports through its exit code rather than by throwing, and codes below 8
            are success: 1 means files were copied, 3 means copied plus extras. 8 and above mean
            at least one file did not make it, which produces media that looks complete and does
            not boot.
    #>
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination,
        [string[]]$Arguments = @()
    )

    & robocopy $Source $Destination @Arguments
    $code = $LASTEXITCODE

    if ($code -ge 8) {
        throw "robocopy could not copy every file from $Source to $Destination (exit code $code)."
    }

    Write-WinUtilISOLog "robocopy finished with exit code $code."
}

function Write-WinUtilISOLog {
    <#
    .SYNOPSIS
        Appends a line to the Win11 Creator status log and to the session log.

    .DESCRIPTION
        The status log is a UI control, so the append is posted to the UI thread rather than
        waited on. Without a window it degrades to the session log alone, which keeps job
        bodies free of "is there a UI" checks.
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    Write-WinUtilLog -Level $Level -Component "Win11Creator" -Message $Message

    Invoke-WPFUIThread -Async -Parameters @{
        LogLine = "[$((Get-Date).ToString('HH:mm:ss'))] $Message"
    } -ScriptBlock {
        param($LogLine)

        $box = $sync["WPFWin11ISOStatusLog"]
        if ($null -eq $box) { return }

        if ($box.Text -eq "Ready. Please select a Windows 11 ISO to begin.") {
            $box.Text = $LogLine
        } else {
            $box.Text += "`n$LogLine"
        }
        $box.CaretIndex = $box.Text.Length
        $box.ScrollToEnd()
    }
}

function Get-WinUtilEditionIdFromName {
    <#
    .SYNOPSIS
        Maps a Windows 11 edition display name to the edition id used by unattended setup.
    #>
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

    Write-WinUtilISOLog "ISO selected: $isoPath  ($fileSizeGB GB)"
}

function Invoke-WinUtilISOMountAndVerify {
    $isoPath = $sync["WPFWin11ISOPath"].Text

    if ([string]::IsNullOrWhiteSpace($isoPath) -or $isoPath -eq "No ISO selected...") {
        Show-WinUtilMessage -Message "Please select an ISO file first." -Title "No ISO Selected" -Button "OK" -Icon "Warning" | Out-Null
        return
    }

    Start-WinUtilJob -Name "ISO mount" -Description "Mounting ISO" -Parameters @{
        IsoPath = $isoPath
    } -ScriptBlock {
        param($isoPath)

        Invoke-WPFUIThread -ScriptBlock {
            $sync["WPFWin11ISOBrowseButton"].IsEnabled = $false
            $sync["WPFWin11ISOMountButton"].IsEnabled = $false
            $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
        }

        try {
            Write-WinUtilISOLog "Mounting ISO: $isoPath"
            Step-WinUtilJob -Status "Mounting ISO..." -Percent 10

            Mount-DiskImage -ImagePath $isoPath -ErrorAction Stop

            # Bounded, because a damaged or already-mounted image may never present a drive
            # letter. The job layer runs one job at a time, so waiting here forever would block
            # every other action and the shutdown wait for the rest of the session.
            $letter = $null
            $mountClock = [System.Diagnostics.Stopwatch]::StartNew()
            while (-not $letter -and $mountClock.Elapsed.TotalSeconds -lt 60) {
                Start-Sleep -Milliseconds 500
                $letter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter
            }

            if (-not $letter) {
                throw "The ISO mounted but no drive letter appeared within 60 seconds: $isoPath"
            }

            $driveLetter = "${letter}:"
            Write-WinUtilISOLog "Mounted at drive $driveLetter"

            Step-WinUtilJob -Status "Verifying ISO contents..." -Percent 30

            $wimPath = Join-Path $driveLetter "sources\install.wim"
            $esdPath = Join-Path $driveLetter "sources\install.esd"

            if (-not (Test-Path $wimPath) -and -not (Test-Path $esdPath)) {
                Dismount-DiskImage -ImagePath $isoPath
                Write-WinUtilISOLog -Level "ERROR" -Message "install.wim/install.esd not found - not a valid Windows ISO."
                Show-WinUtilMessage -Message "This does not appear to be a valid Windows ISO.`n`ninstall.wim / install.esd was not found." -Title "Invalid ISO" -Button "OK" -Icon "Error" | Out-Null
                # Returning here would let the job layer report the run as finished
                throw "install.wim / install.esd was not found in $isoPath."
            }

            $activeWim = if (Test-Path $wimPath) { $wimPath } else { $esdPath }

            Step-WinUtilJob -Status "Reading image metadata..." -Percent 55
            $imageInfo = Get-WindowsImage -ImagePath $activeWim | Select-Object ImageIndex, ImageName

            if (-not ($imageInfo | Where-Object { $_.ImageName -match "Windows 11" })) {
                Dismount-DiskImage -ImagePath $isoPath
                Write-WinUtilISOLog -Level "ERROR" -Message "No 'Windows 11' edition found in the image."
                Show-WinUtilMessage -Message "No Windows 11 edition was found in this ISO.`n`nOnly official Windows 11 ISOs are supported." -Title "Not a Windows 11 ISO" -Button "OK" -Icon "Error" | Out-Null
                throw "No Windows 11 edition was found in $isoPath."
            }

            $sync["Win11ISOImageInfo"] = $imageInfo
            $sync["Win11ISODriveLetter"] = $driveLetter
            $sync["Win11ISOWimPath"]     = $activeWim
            $sync["Win11ISOImagePath"]   = $isoPath

            Invoke-WPFUIThread -Parameters @{
                DriveLetter = $driveLetter
                ImageFileName = Split-Path $activeWim -Leaf
                ImageInfo = $imageInfo
            } -ScriptBlock {
                param($DriveLetter, $ImageFileName, $imageInfo)

                $sync["WPFWin11ISOMountDriveLetter"].Text = "Mounted at: $DriveLetter   |   Image file: $ImageFileName"
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
            }

            Write-WinUtilISOLog "ISO verified OK.  Editions found: $($imageInfo.Count)"
        } finally {
            Invoke-WPFUIThread -ScriptBlock {
                $sync["WPFWin11ISOBrowseButton"].IsEnabled = $true
                $sync["WPFWin11ISOMountButton"].IsEnabled = $true
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
            }
        }
    }
}

function Invoke-WinUtilISOModify {
    $isoPath     = $sync["Win11ISOImagePath"]
    $driveLetter = $sync["Win11ISODriveLetter"]
    $wimPath     = $sync["Win11ISOWimPath"]

    if (-not $isoPath) {
        Show-WinUtilMessage -Message "No verified ISO found. Please complete Steps 1 and 2 first." -Title "Not Ready" -Button "OK" -Icon "Warning" | Out-Null
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

    # A fresh working directory per run; existing-work detection is only for resuming an export
    $workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    if (Test-Path $workDir) {
        $workDir = "$($workDir)_$(([guid]::NewGuid()).ToString('N').Substring(0, 8))"
    }

    $autounattendContent = if ($WinUtilAutounattendXml) {
        $WinUtilAutounattendXml
    } else {
        $toolsXml = Join-Path $PSScriptRoot "..\..\tools\autounattend.xml"
        if (Test-Path $toolsXml) { Get-Content $toolsXml -Raw } else { "" }
    }

    Start-WinUtilJob -Name "ISO modify" -Description "Modifying ISO" -Parameters @{
        IsoPath             = $isoPath
        DriveLetter         = $driveLetter
        WimPath             = $wimPath
        WorkDir             = $workDir
        SelectedWimIndex    = $selectedWimIndex
        SelectedEditionName = $selectedEditionName
        AutounattendContent = $autounattendContent
        InjectDrivers       = $sync["WPFWin11ISOInjectDrivers"].IsChecked -eq $true
    } -ScriptBlock {
        param($isoPath, $DriveLetter, $WimPath, $workDir, $SelectedWimIndex, $SelectedEditionName, $AutounattendContent, $InjectDrivers)

        Invoke-WPFUIThread -ScriptBlock {
            $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
            $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
            $sync["WPFWin11ISOMountSection"].Visibility  = "Collapsed"
            $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
        }

        try {
            Write-WinUtilISOLog "Selected edition: $SelectedEditionName (Index $SelectedWimIndex)"
            Write-WinUtilISOLog "Creating working directory: $workDir"

            $isoContents = Join-Path $workDir "iso_contents"
            New-Item -ItemType Directory -Path $isoContents -Force | Out-Null
            Step-WinUtilJob -Status "Copying ISO contents..." -Percent 10

            Write-WinUtilISOLog "Copying ISO contents from $DriveLetter to $isoContents..."
            Invoke-WinUtilRobocopy -Source $DriveLetter -Destination $isoContents -Arguments @("/E","/NFL","/NDL","/NJH","/NJS")
            Write-WinUtilISOLog "ISO contents copied."
            Step-WinUtilJob -Status "Preparing setup media..." -Percent 25

            $sourceImageFileName = Split-Path $WimPath -Leaf
            $localWim = Join-Path $isoContents "sources\$sourceImageFileName"
            if (-not (Test-Path $localWim)) {
                throw "Copied ISO image file not found: sources\$sourceImageFileName"
            }

            Write-WinUtilISOLog "Writing autounattend.xml and edition selection..."
            Invoke-WinUtilISOScript -ISOContentsDir $isoContents `
                -AutoUnattendXml $AutounattendContent `
                -InjectCurrentSystemDrivers $InjectDrivers `
                -InstallImagePath $localWim `
                -InstallImageIndex $SelectedWimIndex `
                -InstallEditionId (Get-WinUtilEditionIdFromName -EditionName $SelectedEditionName) `
                -Log { param($m) Write-WinUtilISOLog $m }

            Step-WinUtilJob -Status "Preserving install image..." -Percent 70
            if ($InjectDrivers) {
                Write-WinUtilISOLog "Added current-system drivers to $sourceImageFileName index $SelectedWimIndex with one mount and commit."
            } else {
                Write-WinUtilISOLog "Preserved the original $sourceImageFileName without mounting, exporting, or modifying it."
            }

            Step-WinUtilJob -Status "Dismounting source ISO..." -Percent 80
            Write-WinUtilISOLog "Dismounting original ISO..."
            Dismount-DiskImage -ImagePath $isoPath

            $sync["Win11ISOWorkDir"]     = $workDir
            $sync["Win11ISOContentsDir"] = $isoContents

            Step-WinUtilJob -Status "Modification complete" -Percent 100
            Write-WinUtilISOLog "install.wim modification complete. Choose an output option in Step 4."

            Invoke-WPFUIThread -ScriptBlock {
                $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"
            }
        } catch {
            Write-WinUtilISOLog -Level "ERROR" -Message "Modification failed: $_"

            try {
                $mountedISO = Get-DiskImage -ImagePath $isoPath
                if ($mountedISO -and $mountedISO.Attached) {
                    Write-WinUtilISOLog "Cleaning up: dismounting source ISO..."
                    Dismount-DiskImage -ImagePath $isoPath
                }
            } catch { Write-WinUtilISOLog -Level "WARN" -Message "Could not dismount ISO during cleanup: $_" }

            try {
                if (Test-Path $workDir) {
                    Write-WinUtilISOLog "Cleaning up: removing temp directory $workDir..."
                    Remove-Item -Path $workDir -Recurse -Force
                }
            } catch { Write-WinUtilISOLog -Level "WARN" -Message "Could not remove temp directory during cleanup: $_" }

            Show-WinUtilMessage -Message "An error occurred during install.wim modification:`n`n$_" -Title "Modification Error" -Button "OK" -Icon "Error" | Out-Null

            # Let the job layer mark the run as failed
            throw
        } finally {
            Invoke-WPFUIThread -ScriptBlock {
                $sync["WPFWin11ISOModifyButton"].IsEnabled = $true
                if ($sync["WPFWin11ISOOutputSection"].Visibility -ne "Visible") {
                    $sync["WPFWin11ISOSelectSection"].Visibility = "Visible"
                    $sync["WPFWin11ISOMountSection"].Visibility  = "Visible"
                    $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
                }
            }
        }
    }
}

function Invoke-WinUtilISOCheckExistingWork {
    if ($sync["Win11ISOContentsDir"] -and (Test-Path $sync["Win11ISOContentsDir"])) { return }

    # Nothing to resume while a modification is still producing the working directory
    if ($sync.ActiveJob) { return }

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
    Write-WinUtilISOLog "Existing working directory found: $($existingWorkDir.FullName)"
    Write-WinUtilISOLog "Last modified: $modified - Skipping Steps 1-3 and resuming at Step 4."
    Write-WinUtilISOLog "Click 'Clean & Reset' if you want to start over with a new ISO."

    Show-WinUtilMessage -Message "A previous WinUtil ISO working directory was found:`n`n$($existingWorkDir.FullName)`n`n(Last modified: $modified)`n`nStep 4 (output options) has been restored so you can save the already-modified image.`n`nClick 'Clean & Reset' in Step 4 if you want to start over." -Title "Existing Work Found" -Button "OK" -Icon "Info" | Out-Null
}

function Invoke-WinUtilISOCleanAndReset {
    $workDir = $sync["Win11ISOWorkDir"]

    if ($workDir -and (Test-Path $workDir)) {
        $confirm = Show-WinUtilMessage -Message "This will delete the temporary working directory:`n`n$workDir`n`nAnd reset the interface back to the start.`n`nContinue?" -Title "Clean & Reset" -Button "YesNo" -Icon "Warning"
        if ($confirm -ne "Yes") { return }
    }

    Start-WinUtilJob -Name "ISO cleanup" -Description "Cleaning up" -Parameters @{
        WorkDir = $workDir
    } -ScriptBlock {
        param($workDir)

        Invoke-WPFUIThread -ScriptBlock { $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $false }

        try {
            if ($workDir) {
                $mountDir = Join-Path $workDir "wim_mount"
                try {
                    $mountedImages = Get-WindowsImage -Mounted | Where-Object { $_.Path -like "$workDir*" }
                    if ($mountedImages) {
                        foreach ($img in $mountedImages) {
                            Write-WinUtilISOLog "Dismounting WIM at: $($img.Path) (discarding changes)..."
                            Step-WinUtilJob -Status "Dismounting WIM image..." -Percent 3
                            Dismount-WindowsImage -Path $img.Path -Discard
                            Write-WinUtilISOLog "WIM dismounted successfully."
                        }
                    } elseif (Test-Path $mountDir) {
                        Write-WinUtilISOLog "No mounted WIM reported by Get-WindowsImage. Running DISM /Cleanup-Wim as a precaution..."
                        Step-WinUtilJob -Status "Running DISM cleanup..." -Percent 3
                        & dism /English /Cleanup-Wim | ForEach-Object { Write-WinUtilISOLog $_ }
                    }
                } catch {
                    Write-WinUtilISOLog -Level "WARN" -Message "Could not dismount WIM cleanly. Attempting DISM /Cleanup-Wim fallback: $_"
                    try { & dism /English /Cleanup-Wim | ForEach-Object { Write-WinUtilISOLog $_ } }
                    catch { Write-WinUtilISOLog -Level "WARN" -Message "DISM /Cleanup-Wim also failed: $_" }
                }
            }

            if ($workDir -and (Test-Path $workDir)) {
                Write-WinUtilISOLog "Scanning files to delete in: $workDir"
                Step-WinUtilJob -Status "Scanning files..." -Percent 5

                $allFiles = @(Get-ChildItem -Path $workDir -File -Recurse -Force)
                $allDirs  = @(Get-ChildItem -Path $workDir -Directory -Recurse -Force |
                    Sort-Object { $_.FullName.Length } -Descending)
                $total   = $allFiles.Count
                $deleted = 0

                Write-WinUtilISOLog "Found $total files to delete."

                foreach ($f in $allFiles) {
                    try { Remove-Item -Path $f.FullName -Force } catch { Write-WinUtilISOLog -Level "WARN" -Message "Could not delete $($f.FullName): $_" }
                    $deleted++
                    if ($deleted % 100 -eq 0 -or $deleted -eq $total) {
                        $pct = [math]::Round(($deleted / [Math]::Max($total, 1)) * 85) + 5
                        Step-WinUtilJob -Status "Deleting files in $($f.Directory.Name)... ($deleted / $total)" -Percent $pct
                    }
                }

                foreach ($d in $allDirs) {
                    try { Remove-Item -Path $d.FullName -Force } catch { Write-WinUtilISOLog -Level "WARN" -Message "Could not delete $($d.FullName): $_" }
                }

                try { Remove-Item -Path $workDir -Recurse -Force } catch { Write-WinUtilISOLog -Level "WARN" -Message "Could not delete temp directory ${WorkDir}: $_" }

                if (Test-Path $workDir) {
                    Write-WinUtilISOLog -Level "WARN" -Message "Some items could not be deleted in $workDir"
                } else {
                    Write-WinUtilISOLog "Temp directory deleted successfully."
                }
            } else {
                Write-WinUtilISOLog "No temp directory found - resetting UI."
            }

            Step-WinUtilJob -Status "Resetting UI..." -Percent 95
            Write-WinUtilISOLog "Resetting interface..."

            $sync["Win11ISOWorkDir"]     = $null
            $sync["Win11ISOContentsDir"] = $null
            $sync["Win11ISOImagePath"]   = $null
            $sync["Win11ISODriveLetter"] = $null
            $sync["Win11ISOWimPath"]     = $null
            $sync["Win11ISOImageInfo"]   = $null
            $sync["Win11ISOUSBDisks"]    = $null

            Invoke-WPFUIThread -ScriptBlock {
                $sync["WPFWin11ISOPath"].Text                    = "No ISO selected..."
                $sync["WPFWin11ISOFileInfo"].Visibility          = "Collapsed"
                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
                $sync["WPFWin11ISOOptionUSB"].Visibility         = "Collapsed"
                $sync["WPFWin11ISOOutputSection"].Visibility     = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility     = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility      = "Collapsed"
                $sync["WPFWin11ISOSelectSection"].Visibility     = "Visible"
                $sync["WPFWin11ISOModifyButton"].IsEnabled       = $true
                $sync["WPFWin11ISOStatusLog"].Text               = "Ready. Please select a Windows 11 ISO to begin."
            }
            Step-WinUtilJob -Hide
        } finally {
            Invoke-WPFUIThread -ScriptBlock { $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $true }
        }
    }
}

function Get-WinUtilOSCDImgPath {
    # Windows ADK installation
    $oscdimg = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
               Select-Object -First 1 -ExpandProperty FullName
    if (-not $oscdimg) {
        # Per-user winget installation
        $oscdimg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
                   Where-Object { $_.FullName -match 'Microsoft\.OSCDIMG' } |
                   Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not $oscdimg) {
        # Installation available through the current process PATH
        $oscdimg = Get-Command oscdimg.exe -CommandType Application -ErrorAction SilentlyContinue |
                   Select-Object -First 1 -ExpandProperty Source
    }

    if (-not $oscdimg) {
        # WinGet links that may not yet be available through the current process PATH
        $oscdimg = @(
            "$env:LOCALAPPDATA\Microsoft\WinGet\Links\oscdimg.exe"
            "$env:ProgramFiles\WinGet\Links\oscdimg.exe"
        ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    }

    return $oscdimg
}

function Invoke-WinUtilISOExport {
    $contentsDir = $sync["Win11ISOContentsDir"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        Show-WinUtilMessage -Message "No modified ISO content found.  Please complete Steps 1-3 first." -Title "Not Ready" -Button "OK" -Icon "Warning" | Out-Null
        return
    }

    Add-Type -AssemblyName System.Windows.Forms

    $dlg = [System.Windows.Forms.SaveFileDialog]::new()
    $dlg.Title            = "Save Modified Windows 11 ISO"
    $dlg.Filter           = "ISO files (*.iso)|*.iso"
    $dlg.FileName         = "Win11_Modified_$(Get-Date -Format 'yyyyMMdd').iso"
    $dlg.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    Start-WinUtilJob -Name "ISO export" -Description "Building ISO" -Parameters @{
        ContentsDir = $contentsDir
        OutputISO   = $dlg.FileName
    } -ScriptBlock {
        param($contentsDir, $outputISO)

        Invoke-WPFUIThread -ScriptBlock { $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false }

        try {
            $oscdimg = Get-WinUtilOscdimgPath
            if (-not $oscdimg) {
                Show-WinUtilMessage -Message "oscdimg.exe could not be found or installed automatically.`n`nPlease install it manually:`n  winget install -e --id Microsoft.OSCDIMG`n`nOr install the Windows ADK from:`nhttps://learn.microsoft.com/windows-hardware/get-started/adk-install" -Title "oscdimg Not Found" -Button "OK" -Icon "Warning" | Out-Null
                throw "oscdimg.exe could not be found or installed automatically."
            }

            Write-WinUtilISOLog "Exporting to ISO: $outputISO"
            Step-WinUtilJob -Status "Building ISO..." -Percent 10

            $bootData    = "2#p0,e,b`"$contentsDir\boot\etfsboot.com`"#pEF,e,b`"$contentsDir\efi\microsoft\boot\efisys.bin`""
            $oscdimgArgs = @("-m", "-o", "-u2", "-udfver102", "-bootdata:$bootData", "-l`"CTOS_MODIFIED`"", "`"$contentsDir`"", "`"$outputISO`"")

            Write-WinUtilISOLog "Running oscdimg..."

            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName               = $oscdimg
            $psi.Arguments              = $oscdimgArgs -join " "
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError  = $true
            $psi.UseShellExecute        = $false
            $psi.CreateNoWindow         = $true

            $proc = [System.Diagnostics.Process]::new()
            $proc.StartInfo = $psi

            # stderr is collected as it arrives rather than after the process exits. Reading it
            # last deadlocks: once the stderr pipe fills, oscdimg blocks on its write and stops
            # producing stdout, while this loop waits for stdout that will never come.
            $stderrLines = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
            $proc.EnableRaisingEvents = $true
            $errorHandler = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
                if ($EventArgs.Data) { $null = $Event.MessageData.Add($EventArgs.Data) }
            } -MessageData $stderrLines

            try {
                $proc.Start() | Out-Null
                $proc.BeginErrorReadLine()

                # Stream stdout line-by-line as oscdimg runs
                while (-not $proc.StandardOutput.EndOfStream) {
                    $line = $proc.StandardOutput.ReadLine()
                    if ($line.Trim()) { Write-WinUtilISOLog $line }
                }

                $proc.WaitForExit()
            } finally {
                Unregister-Event -SourceIdentifier $errorHandler.Name -ErrorAction SilentlyContinue
                $errorHandler | Remove-Job -Force -ErrorAction SilentlyContinue
            }

            foreach ($line in @($stderrLines)) {
                if ($line.Trim()) { Write-WinUtilISOLog -Level "WARN" -Message "[stderr]$line" }
            }

            if ($proc.ExitCode -ne 0) {
                throw "oscdimg exited with code $($proc.ExitCode). Check the status log for details."
            }

            Step-WinUtilJob -Status "ISO exported" -Percent 100
            Write-WinUtilISOLog "ISO exported successfully: $outputISO"
            Show-WinUtilMessage -Message "ISO exported successfully!`n`n$outputISO" -Title "Export Complete" -Button "OK" -Icon "Info" | Out-Null
        } catch {
            Write-WinUtilISOLog -Level "ERROR" -Message "ISO export failed: $_"
            Show-WinUtilMessage -Message "ISO export failed:`n`n$_" -Title "Error" -Button "OK" -Icon "Error" | Out-Null
            throw
        } finally {
            Invoke-WPFUIThread -ScriptBlock { $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $true }
        }
    }
}

function Find-WinUtilOscdimg {
    <#
    .SYNOPSIS
        Looks for oscdimg.exe in every place it is known to land

    .DESCRIPTION
        PATH first, since that covers an ADK installed anywhere and a manual copy, then the
        default ADK location, then the per-user WinGet package root. Used both before and after
        the install attempt, so a package that lands outside the per-user root is still found.
    #>

    $onPath = Get-Command oscdimg.exe -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    foreach ($root in @(
            "${env:ProgramFiles(x86)}\Windows Kits",
            "$env:ProgramFiles\Windows Kits",
            "$env:LOCALAPPDATA\Microsoft\WinGet\Packages")) {

        if (-not $root -or -not (Test-Path $root)) { continue }

        $found = Get-ChildItem $root -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
                 Select-Object -First 1 -ExpandProperty FullName
        if ($found) { return $found }
    }

    return $null
}

function Get-WinUtilOscdimgPath {
    <#
    .SYNOPSIS
        Returns the path to oscdimg.exe, installing it through winget when it is missing.
    #>

    $oscdimg = Find-WinUtilOscdimg
    if ($oscdimg) { return $oscdimg }

    Write-WinUtilISOLog "oscdimg.exe not found. Attempting to install via winget..."
    try {
        # First ensure winget is installed and operational
        Install-WinUtilWinget

        $winget = Get-Command winget
        $result = & $winget install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements
        Write-WinUtilISOLog "winget output: $result"

        # The same search as before the install: winget honours a configured scope and package
        # root, so the file does not necessarily land under the per-user package directory
        $oscdimg = Find-WinUtilOscdimg
    } catch {
        Write-WinUtilISOLog -Level "WARN" -Message "winget not available or install failed: $_"
    }

    if ($oscdimg) {
        Write-WinUtilISOLog "oscdimg.exe installed successfully."
    } else {
        Write-WinUtilISOLog -Level "ERROR" -Message "oscdimg.exe still not found after install attempt."
    }
    return $oscdimg
}
