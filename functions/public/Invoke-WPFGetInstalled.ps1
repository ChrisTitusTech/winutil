function Invoke-WPFGetInstalled {
    <#
    .SYNOPSIS
        Invokes the function that gets the checkboxes to check in a new runspace

    .PARAMETER checkbox
        Indicates whether to check for installed 'winget' programs or applied 'tweaks'

    #>
    param($checkbox)
    if ($sync.ProcessRunning) {
        $msg = "[Invoke-WPFGetInstalled] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if (($sync.ChocoRadioButton.IsChecked -eq $false) -and ((Test-WinUtilPackageManager -winget) -eq "not-installed") -and $checkbox -eq "winget") {
        return
    }
    $managerPreference = $sync.preferences.packagemanager

    Invoke-WPFRunspace -ParameterList @(("managerPreference", $managerPreference),("checkbox", $checkbox)) -ScriptBlock {
        param (
            [string]$checkbox,
            [string]$managerPreference
        )
        $sync.ProcessRunning = $true
        try {
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Indeterminate" }

            if ($checkbox -eq "winget") {
                Write-Host "Getting Installed Programs..."
                switch ($managerPreference) {
                    "Choco"{$Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox "choco"; break}
                    "Winget"{$Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox $checkbox; break}
                }
            }
            elseif ($checkbox -eq "tweaks") {
                Write-Host "Getting Installed Tweaks..."
                $Checkboxes = Invoke-WinUtilCurrentSystem -CheckBox $checkbox
            }

            Invoke-WPFUIThread -ScriptBlock {
                if ($checkbox -eq "winget") {
                    foreach ($checkboxName in $Checkboxes) {
                        if (-not $sync.selectedApps.Contains($checkboxName)) {
                            $sync.selectedApps.Add($checkboxName)
                        }
                    }
                    Reset-WPFCheckBoxes -checkboxfilterpattern "WPFInstall*"
                } else {
                    foreach ($checkboxName in $Checkboxes) {
                        $sync.$checkboxName.ischecked = $True
                    }
                }
            }

            Write-Host "Done..."
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Install" -Message "Get installed state failed: $($_.Exception.Message)"
            Write-Warning "Unable to get installed state: $($_.Exception.Message)"
        } finally {
            $sync.ProcessRunning = $false
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "None" }
        }
    }
}
