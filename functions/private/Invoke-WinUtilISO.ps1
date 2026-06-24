function Write-Win11ISOLog ($Message) {
    $time = Get-Date -Format hh:mm:ss
    $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
        $sync["WPFWin11ISOStatusLog"].Text += "`n[$time] $Message"
        $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
    })
}

function Invoke-WinUtilRunspace ($ScriptBlock, $Variables = @{}) {
    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()

    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("winutildir", $winutildir)

    foreach ($kvp in $Variables.GetEnumerator()) {
        $runspace.SessionStateProxy.SetVariable($kvp.Key, $kvp.Value)
    }

    $funcDef = "function Write-Win11ISOLog {`n" + ${function:Write-Win11ISOLog}.ToString() + "`n}"
    $wrappedScript = [scriptblock]::Create($funcDef + "`n`n" + $ScriptBlock.ToString())

    $script = [Management.Automation.PowerShell]::Create()
    $script.Runspace = $runspace
    $script.AddScript($wrappedScript)
    return $script.BeginInvoke()
}

function Invoke-WinUtilISOBrowse {
    $dialog = [System.Windows.Forms.OpenFileDialog]::new()
    $dialog.Title = "Select Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso|All files (*.*)|*.*"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $sync["WPFWin11ISOPath"].Text = $dialog.FileName
    $sync["WPFWin11ISOFileInfo"].Text = "File size: $([math]::Round((Get-Item -Path $dialog.FileName).Length / 1GB, 2)) GB"
    $sync["WPFWin11ISOFileInfo"].Visibility = "Visible"
    $sync["WPFWin11ISOMountSection"].Visibility = "Visible"
    $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility = "Collapsed"
}

function Invoke-WinUtilISOMount {
    $sync["WPFWin11ISOMountButton"].IsEnabled = $false

    Invoke-WinUtilRunspace -Variables @{ isoPath = $sync["WPFWin11ISOPath"].Text } -ScriptBlock {
        try {
            $time = Get-Date -Format hh:mm:ss
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOStatusLog"].Text = "[$time] Mounting ISO: $isoPath..."
                $sync["WPFWin11ISOStatusLog"].ScrollToEnd()
            })

            Mount-DiskImage -ImagePath $isoPath
            $driveLetter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter + ":"

            $activeWim = if (Test-Path "$driveLetter\sources\install.wim") {
                "$driveLetter\sources\install.wim"
            } else {
                "$driveLetter\sources\install.esd"
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
                        if ($sync["WPFWin11ISOEditionComboBox"].Items[$i] -match "^\d+:\s*Windows 11 Pro$") {
                            $proIndex = $i; break
                        }
                    }
                    $sync["WPFWin11ISOEditionComboBox"].SelectedIndex = if ($proIndex -ge 0) { $proIndex } else { 0 }
                }

                $sync["WPFWin11ISOVerifyResultPanel"].Visibility = "Visible"
                $sync["WPFWin11ISOModifySection"].Visibility = "Visible"
            })

            Write-Win11ISOLog "ISO Mounted to $driveLetter"
        } catch {
            Write-Win11ISOLog "ERROR during mount: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred while mounting the ISO:`n`n$_",
                    "Error", "OK", "Error")
            })
        } finally {
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

    $sync["WPFWin11ISOModifyButton"].IsEnabled = $false
    $sync["Win11ISOModifying"] = $true

    Invoke-WinUtilRunspace -Variables @{
        isoPath = $isoPath
        driveLetter = $driveLetter
        workDir = "$winutildir\Win11Creator"
        selectedWimIndex = $selectedWimIndex
        selectedEditionName = $selectedEditionName
        autounattendContent = $WinUtilAutounattendXml
        injectDrivers = $injectDrivers
    } -ScriptBlock {
        try {
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
                $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
            })

            $isoContents = "$workDir\iso_contents"
            New-Item -Path $isoContents -ItemType Directory -Force

            Write-Win11ISOLog "Copying ISO Contents from $driveLetter to $isoContents..."

            Copy-Item -Path "$driveLetter\*" -Destination $isoContents -Recurse -Force
            Dismount-DiskImage -ImagePath $isoPath

            Write-Win11ISOLog "ISO contents copied to $isoContents."

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
                Write-Win11ISOLog "Exporting Windows drivers to $winutildir\Driver..."
                Export-WindowsDriver -Destination "$winutildir\Driver" -Online

                Set-ItemProperty -Path $localWim -Name IsReadOnly -Value $false
                New-Item -Path "$workDir\wim_mount" -ItemType Directory -Force

                Write-Win11ISOLog "Mounting and adding drivers to $localWim..."
                Mount-WindowsImage -ImagePath $localWim -Index $selectedWimIndex -Path "$workDir\wim_mount"
                Add-WindowsDriver -Path "$workDir\wim_mount" -Driver "$winutildir\Driver" -Recurse

                Write-Win11ISOLog "Saving $localWim..."
                Dismount-WindowsImage -Path "$workDir\wim_mount" -Save

                Set-ItemProperty -Path "$isoContents\sources\boot.wim" -Name IsReadOnly -Value $false
                New-Item -Path "$workDir\boot_mount" -ItemType Directory -Force

                Write-Win11ISOLog "Adding drivers to $isoContents\sources\boot.wim...."
                Mount-WindowsImage -ImagePath "$isoContents\sources\boot.wim" -Index 2 -Path "$workDir\boot_mount"
                Add-WindowsDriver -Path "$workDir\boot_mount" -Driver "$winutildir\Driver" -Recurse

                Write-Win11ISOLog "Saving $isoContents\sources\boot.wim..."
                Dismount-WindowsImage -Path "$workDir\boot_mount" -Save

                Remove-Item -Path "$winutildir\Driver" -Recurse -Force
                Write-Win11ISOLog "Driver injection completed"
            }

            Write-Win11ISOLog "Exporting $localWim into a single-edition install.wim..."

            $exportWim = "$isoContents\sources\install_export.wim"
            Export-WindowsImage -SourceImagePath $localWim -SourceIndex $selectedWimIndex -DestinationImagePath $exportWim

            Remove-Item -Path $localWim -Force
            Rename-Item -Path $exportWim -NewName "install.wim" -Force

            Write-Win11ISOLog "Unused editions removed."

            $sync["Win11ISOContentsDir"] = $isoContents

            Write-Win11ISOLog "Win11Creator ISO created successfully. Choose an output option in Step 4."
            $sync["WPFWin11ISOOutputSection"].Dispatcher.Invoke([action]{
                $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"
            })
        } catch {
            Write-Win11ISOLog "ERROR during modification: $_"
            $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
                [System.Windows.MessageBox]::Show(
                    "An error occurred during Win11Creator ISO creation:`n`n$_",
                    "Modification Error", "OK", "Error")
            })
        } finally {
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

function Invoke-WinUtilISOExport {
    $dialog = [System.Windows.Forms.SaveFileDialog]::new()
    $dialog.Title = "Save Modified Windows 11 ISO"
    $dialog.Filter = "ISO files (*.iso)|*.iso"
    $dialog.FileName = "Win11Creator.iso"

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $sync["WPFWin11ISOChooseISOButton"].IsEnabled = $false

    Invoke-WinUtilRunspace -Variables @{
        contentsDir = $sync["Win11ISOContentsDir"]
        outputISO = $dialog.FileName
    } -ScriptBlock {
        try {
            Write-Win11ISOLog "Exporting to $outputISO"

            Invoke-WebRequest -Uri "https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe" -OutFile "$winutildir\oscdimg.exe"
            & "$winutildir\oscdimg.exe" -o -u2 "-b$contentsDir\efi\microsoft\boot\efisys.bin" $contentsDir $outputISO

            Write-Win11ISOLog "ISO successfully exported."
            [System.Windows.MessageBox]::Show("ISO successfully exported.", "Export Complete", "OK", "Info")
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

function Invoke-WinUtilISOCheckExistingWork {
    if (-not (Test-Path "$winutildir\Win11Creator\iso_contents")) { return }
    if ($sync["Win11ISOModifying"]) { return }

    $sync["Win11ISOContentsDir"] = "$winutildir\Win11Creator\iso_contents"

    $sync["WPFWin11ISOSelectSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOMountSection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOModifySection"].Visibility = "Collapsed"
    $sync["WPFWin11ISOOutputSection"].Visibility = "Visible"

    [System.Windows.MessageBox]::Show(
        "Found existing work in:`n$winutildir\Win11Creator`n`nStep 4 restored. Click 'Clean & Reset' to start over.",
        "Existing Work Found", "OK", "Info")
}

function Invoke-WinUtilISOCleanAndReset {
    $sync["WPFWin11ISOCleanResetButton"].IsEnabled = $false

    Invoke-WinUtilRunspace -ScriptBlock {
        Write-Win11ISOLog "Removing temporary working directories..."
        Remove-Item -Path "$winutildir\Win11Creator", "$winutildir\Driver" -Recurse -Force

        $sync["WPFWin11ISOStatusLog"].Dispatcher.Invoke([action]{
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
