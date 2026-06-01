function Write-Win11ISOLog ($Message) {
    $time = Get-Date -Format hh:mm:ss

    $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
        $sync["WPFWin11ISOStatusLog"].Text += "`n[$time] $Message"
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
    return $script.BeginInvoke()
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

function Invoke-WinUtilISOMount {
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

            if (Test-Path "$driveLetter\sources\install.wim") {
                $activeWim = "$driveLetter\sources\install.wim"
            } else {
                $activeWim = "$driveLetter\sources\install.esd"
            }

            $imageInfo = Get-WindowsImage -ImagePath $activeWim | Select-Object ImageIndex, ImageName

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
            Write-Win11ISOLog "ERROR during mount: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred while mounting the ISO:`n`n$_",
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

    $workDir = "$Env:Temp\Win11Creator"

    Invoke-WinUtilRunspace -Variables @{
        isoPath = $isoPath
        driveLetter = $driveLetter
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
            New-Item -Path $isoContents -ItemType Directory -Force

            Write-Win11ISOLog "Copying ISO contents..."
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = "Copying ISO contents..."
                $sync.ProgressBar.IsIndeterminate = $true
            })
            Copy-Item -Path "$driveLetter\*" -Destination $isoContents -Recurse -Force
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.ProgressBar.IsIndeterminate = $false
            })
            Dismount-DiskImage -ImagePath $isoPath

            Write-Win11ISOLog "ISO contents copied."

            $localWim = if (Test-Path "$isoContents\sources\install.wim") {
                "$isoContents\sources\install.wim"
            } else {
                "$isoContents\sources\install.esd"
            }

            Set-Content -Path "$isoContents\autounattend.xml" -Value $autounattendContent
            Write-Win11ISOLog "Written autounattend.xml to ISO root."

            Remove-Item -Path "$isoContents\support" -Recurse -Force
            Write-Win11ISOLog "Removed support folder from ISO root."

            if ($injectDrivers) {
                Write-Win11ISOLog "Exporting Windows drivers..."
                Export-WindowsDriver -Destination "$Env:Temp\Driver" -Online

                Set-ItemProperty -Path $localWim -Name IsReadOnly -Value $false
                New-Item -Path "$workDir\wim_mount" -ItemType Directory -Force

                Write-Win11ISOLog "Mounting and adding drivers to $localWim..."
                Mount-WindowsImage -ImagePath $localWim -Index $selectedWimIndex -Path "$workDir\wim_mount"
                Add-WindowsDriver -Path "$workDir\wim_mount" -Driver "$Env:Temp\Driver" -Recurse

                Write-Win11ISOLog "Saving install.wim"
                Dismount-WindowsImage -Path "$workDir\wim_mount" -Save

                Set-ItemProperty -Path "$isoContents\sources\boot.wim" -Name IsReadOnly -Value $false
                New-Item -Path "$workDir\boot_mount" -ItemType Directory -Force

                Write-Win11ISOLog "Adding drivers to boot.wim (Index 1)"
                Mount-WindowsImage -ImagePath "$isoContents\sources\boot.wim" -Index 1 -Path "$workDir\boot_mount"
                Add-WindowsDriver -Path "$workDir\boot_mount" -Driver "$Env:Temp\Driver" -Recurse

                Write-Win11ISOLog "Saving boot.wim (Index 1)"
                Dismount-WindowsImage -Path "$workDir\boot_mount" -Save

                Write-Win11ISOLog "Adding drivers to boot.wim (Index 2)"
                Mount-WindowsImage -ImagePath "$isoContents\sources\boot.wim" -Index 2 -Path "$workDir\boot_mount"
                Add-WindowsDriver -Path "$workDir\boot_mount" -Driver "$Env:Temp\Driver" -Recurse

                Write-Win11ISOLog "Saving boot.wim (Index 2)"
                Dismount-WindowsImage -Path "$workDir\boot_mount" -Save

                Remove-Item -Path "$Env:Temp\Driver" -Recurse -Force
                Write-Win11ISOLog "Driver injection completed"
            }

            Write-Win11ISOLog "Exporting install.wim into a single-edition install.wim..."

            $exportWim = "$isoContents\sources\install_export.wim"
            Export-WindowsImage -SourceImagePath $localWim -SourceIndex $selectedWimIndex -DestinationImagePath $exportWim

            Remove-Item -Path $localWim -Force
            Rename-Item -Path $exportWim -NewName "install.wim" -Force

            Write-Win11ISOLog "Unused editions removed."
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
            Remove-Item -Path "$Env:Temp\Driver" -Recurse -Force
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
                $sync.ProgressBar.IsIndeterminate = $false
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

    $isoContents = "$Env:Temp\Win11Creator\iso_contents"
    if (-not (Test-Path $isoContents)) { return }

    $sync["Win11ISOWorkDir"] = "$Env:Temp\Win11Creator"
    $sync["Win11ISOContentsDir"] = $isoContents

    $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"

    $existingWorkDir = Get-Item "$Env:Temp\Win11Creator"
    $modified = $existingWorkDir.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    Write-Win11ISOLog "Existing working directory found: $Env:Temp\Win11Creator"
    Write-Win11ISOLog "Last modified: $modified - Skipping Steps 1-3 and resuming at Step 4."
    Write-Win11ISOLog "Click 'Clean & Reset' if you want to start over with a new ISO."

    [System.Windows.MessageBox]::Show(
        "A previous WinUtil ISO working directory was found:`n`n$Env:Temp\Win11Creator`n`n(Last modified: $modified)`n`nStep 4 (output options) has been restored so you can save the already-modified image.`n`nClick 'Clean & Reset' in Step 4 if you want to start over.",
        "Existing Work Found", "OK", "Info")
}

function Invoke-WinUtilISOCleanAndReset {
    $confirm = [System.Windows.MessageBox]::Show(
        "This will delete the temporary working directory:`n`n$($sync["Win11ISOWorkDir"])`n`nAnd reset the interface back to the start.`n`nContinue?",
        "Clean And Reset", "YesNo", "Warning")

    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

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
        Remove-Item -Path "$Env:Temp\Win11Creator" -Recurse -Force
        Remove-Item -Path "$Env:Temp\Driver" -Recurse -Force

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

    $dialog = [System.Windows.Forms.SaveFileDialog]::new()
    $dialog.Title = "Save Modified Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.FileName = "Win11Creator.iso"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $outputISO = $dialog.FileName
    $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false

    Invoke-WinUtilRunspace -Variables @{
        contentsDir = $contentsDir
        outputISO = $outputISO
    } -ScriptBlock {
        . ([scriptblock]::Create($win11ISOLogFuncDef))

        try {
            $oscdimg = "$Env:Temp\oscdimg.exe"
            Invoke-WebRequest -Uri "https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe" -OutFile $oscdimg

            Write-Win11ISOLog "Exporting to ISO: $outputISO"
            & $oscdimg -o -u2 "-b$contentsDir\efi\microsoft\boot\efisys.bin" $contentsDir $outputISO

            if ($LASTEXITCODE -ne 0) {
                Write-Win11ISOLog "oscdimg exited with code $LASTEXITCODE"
                return
            }

            Write-Win11ISOLog "ISO exported successfully: $outputISO"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show("ISO exported successfully!`n`n$outputISO", "Export Complete", "OK", "Info")
            })
        } catch {
            Write-Win11ISOLog "ERROR during ISO export: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show("ISO export failed:`n`n$_", "Error", "OK", "Error")
            })
        } finally {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync.progressBarTextBlock.Text = ""
                $sync.progressBarTextBlock.ToolTip = ""
                $sync.ProgressBar.Value = 0
                $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $true
            })
        }
    }
}
