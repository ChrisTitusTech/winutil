function Write-Win11ISOLog ($Message) {
    $time = Get-Date -Format hh:mm:ss

    $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
        $sync["WPFWin11ISOStatusLog"].Text = "[$time] $Message"
        $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
    })
}

function Invoke-WinUtilRunspace ([scriptblock]$ScriptBlock, [hashtable]$Variables = @{}) {
    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()

    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("win11ISOLogFuncDef",
        "function Write-Win11ISOLog {`n" + ${function:Write-Win11ISOLog}.ToString() + "`n}")

    foreach ($kvp in $Variables.GetEnumerator()) {
        $runspace.SessionStateProxy.SetVariable($kvp.Key, $kvp.Value)
    }

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript($ScriptBlock)
    $script.BeginInvoke()
}

function Invoke-WinUtilISOBrowse {
    $dialog = [System.Windows.Forms.OpenFileDialog]::new()
    $dialog.Title = "Select Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso|All files (*.*)|*.*"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $isoPath = $dialog.FileName
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

    $sync["WPFWin11ISOMountButton"].IsEnabled = $false
    Write-Win11ISOLog "Mounting ISO: $isoPath"

    Invoke-WinUtilRunspace -Variables @{ isoPath = $isoPath } -ScriptBlock {
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        try {
            Mount-DiskImage -ImagePath $isoPath

            do { Start-Sleep -Milliseconds 100 } until ((Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter)

            $driveLetter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter + ":"
            Write-Win11ISOLog "Mounted at drive $driveLetter"

            $wimPath = "$driveLetter\sources\install.wim"
            $esdPath = "$driveLetter\sources\install.esd"

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
    }
}

function Invoke-WinUtilISOModify {
    $isoPath = $sync["Win11ISOImagePath"]
    $driveLetter = $sync["Win11ISODriveLetter"]
    $wimPath = $sync["Win11ISOWimPath"]
    $selectedItem = $sync["WPFWin11ISOEditionComboBox"].SelectedItem
    $injectDrivers = $sync["WPFWin11ISOInjectDrivers"].IsChecked -eq $true

    $selectedWimIndex = if ($selectedItem -and $selectedItem -match '^(\d+):') {
        [int]$Matches[1]
    } elseif ($sync["Win11ISOImageInfo"]) {
        $sync["Win11ISOImageInfo"][0].ImageIndex
    }

    $selectedEditionName = if ($selectedItem) { ($selectedItem -replace '^\d+:\s*', '') } else { "Unknown" }
    Write-Win11ISOLog "Selected edition: $selectedEditionName (Index $selectedWimIndex)"

    $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
    $sync["Win11ISOModifying"] = $true

    $workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    Invoke-WinUtilRunspace -Variables @{
        isoPath = $isoPath
        driveLetter = $driveLetter
        wimPath = $wimPath
        workDir = $workDir
        selectedWimIndex = $selectedWimIndex
        selectedEditionName = $selectedEditionName
        autounattendContent = $WinUtilAutounattendXml
        injectDrivers = $injectDrivers
    } -ScriptBlock {
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        try {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
            })

            $isoContents = "$workDir\iso_contents"
            $mountDir = "$workDir\wim_mount"

            New-Item -Path $isoContents, $mountDir -ItemType Directory -Force

            Write-Win11ISOLog "Copying ISO contents... from $driveLetter to $isoContents"
            Copy-Item -Path "$driveLetter\*" -Destination $isoContents -Recurse -Force
            Write-Win11ISOLog "ISO contents copied."

            $localWim = if (Test-Path "$isoContents\sources\install.wim") {
                "$isoContents\sources\install.wim"
            } else {
                "$isoContents\sources\install.esd"
            }

            Set-ItemProperty -Path $localWim -Name IsReadOnly -Value $false

            Write-Win11ISOLog "Mounting install.wim... (Index ${selectedWimIndex}: $selectedEditionName) at $mountDir"
            Mount-WindowsImage -ImagePath $localWim -Index $selectedWimIndex -Path $mountDir

            Set-Content -Path "$isoContents\autounattend.xml" -Value $autounattendContent
            Write-Win11ISOLog "Written autounattend.xml to ISO root."

            Remove-Item -Path "$isoContents\support" -Recurse -Force
            Write-Win11ISOLog "Removed support folder from ISO root."

            if ($injectDrivers) {
                Write-Win11ISOLog "Injecting current system drivers (This might take a few minutes)..."

                New-Item -Path "$Env:Temp\Driver" -ItemType Directory

                Export-WindowsDriver -Online -Destination "$Env:Temp\Driver"
                Add-WindowsDriver -Path $mountDir -Driver "$Env:Temp\Driver" -Recurse

                Remove-Item -Path "$Env:Temp\Driver" -Recurse -Force
            }

            Write-Win11ISOLog "Running DISM component store cleanup (/ResetBase). this may take a few minutes..."
            Repair-WindowsImage -Path $mountDir -StartComponentCleanup -ResetBase
            Write-Win11ISOLog "Component store cleanup complete."

            Write-Win11ISOLog "Dismounting and saving install.wim. This will take several minutes..."
            Dismount-WindowsImage -Path $mountDir -Save
            Write-Win11ISOLog "install.wim saved."

            Write-Win11ISOLog "Exporting edition '$selectedEditionName' (Index $selectedWimIndex) to a single-edition install.wim..."

            $exportWim = "$isoContents\sources\install_export.wim"

            Export-WindowsImage -SourceImagePath $localWim -SourceIndex $selectedWimIndex -DestinationImagePath $exportWim

            Remove-Item -Path $localWim -Force
            Rename-Item -Path $exportWim -NewName "install.wim" -Force

            Write-Win11ISOLog "Unused editions removed. install.wim now contains only '$selectedEditionName'."

            Write-Win11ISOLog "Dismounting original ISO..."
            Dismount-DiskImage -ImagePath $isoPath

            $sync["Win11ISOWorkDir"] = $workDir
            $sync["Win11ISOContentsDir"] = $isoContents

            Write-Win11ISOLog "install.wim modification complete. Choose an output option in Step 4."
            $sync["WPFWin11ISOOutputSection"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"
            })

        } catch {
            Write-Win11ISOLog "ERROR during modification: $_"
            Dismount-DiskImage -ImagePath $isoPath
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
                    $sync["WPFWin11ISOMountSection"].Visibility  = "Visible"
                    $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
                }
            })
        }
    }
}

function Invoke-WinUtilISOCheckExistingWork {
    if ($sync["Win11ISOContentsDir"] -and (Test-Path $sync["Win11ISOContentsDir"])) { return }
    if ($sync["Win11ISOModifying"]) { return }

    $existingWorkDir = Get-Item -Path "$Env:Temp\WinUtil_Win11ISO*"

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
    Write-Win11ISOLog "Click 'Clean & Reset' if you want to start over with a new ISO."

    [System.Windows.MessageBox]::Show(
        "A previous WinUtil ISO working directory was found:`n`n$($existingWorkDir.FullName)`n`n(Last modified: $modified)`n`nStep 4 (output options) has been restored so you can save the already-modified image.`n`nClick 'Clean & Reset' in Step 4 if you want to start over.",
        "Existing Work Found", "OK", "Info")
}

function Invoke-WinUtilISOCleanAndReset {
    $confirm = [System.Windows.MessageBox]::Show("This will delete the temporary working directory:`n`n$workDir`n`nAnd reset the interface back to the start.`n`nContinue?","Clean And Reset", "YesNo", "Warning")

    $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $false

    Invoke-WinUtilRunspace -ScriptBlock {
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        Write-Win11ISOLog "Dismounting mounted Windows images... This might take a few minutes"
        foreach ($image in Get-WindowsImage -Mounted) {
            Dismount-WindowsImage -Path $image.Path -Discard
        }

        Write-Win11ISOLog "Dismounting mounted ISOs..."
        foreach ($cdrom in (Get-Volume | Where-Object DriveType -eq 'CD-ROM')) {
            Dismount-DiskImage -DevicePath "\\.\$($cdrom.DriveLetter):"
        }

        Write-Win11ISOLog "Removing temporary working directories..."
        Remove-Item -Path "$Env:Temp\WinUtil_Win11ISO*" -Recurse -Force

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
    }
}

function Invoke-WinUtilISOExport {
    $contentsDir = $sync["Win11ISOContentsDir"]

    if (-not $contentsDir -or -not (Test-Path $contentsDir)) {
        [System.Windows.MessageBox]::Show(
            "No modified ISO content found.  Please complete Steps 1-3 first.",
            "Not Ready", "OK", "Warning")
        return
    }

    $dialog = [System.Windows.Forms.SaveFileDialog]::new()
    $dialog.Title = "Save Modified Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.FileName = "Win11_Modified_$(Get-Date -Format 'yyyyMMdd').iso"
    $dialog.InitialDirectory = [System.Environment]::GetFolderPath("Desktop")

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $outputISO = $dialog.FileName
    $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false

    Invoke-WinUtilRunspace -Variables @{
        contentsDir = $contentsDir
        outputISO = $outputISO
    } -ScriptBlock {
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        $oscdimg = "$Env:Temp\oscdimg.exe"
        Invoke-WebRequest -Uri "https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe" -OutFile $oscdimg

        Write-Win11ISOLog "Exporting to ISO: $outputISO"
        & $oscdimg -m -o -h -u2 -udfver102 -efi "-b$contentsDir\efi\microsoft\boot\efisys.bin" -lCTOS_MODIFIED $contentsDir $outputISO

        Write-Win11ISOLog "ISO exported successfully: $outputISO"
        $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
            [System.Windows.MessageBox]::Show("ISO exported successfully!`n`n$outputISO", "Export Complete", "OK", "Info")
            $sync.progressBarTextBlock.Text = ""
            $sync.progressBarTextBlock.ToolTip = ""
            $sync.ProgressBar.Value = 0
            $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $true
        })
    }
}
