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
    $operation = [Hashtable]::Synchronized(@{
        Checkboxes = @()
        Error = $null
    })
    $completeAction = [Action[hashtable, string]]{
        param(
            [hashtable]$completedOperation,
            [string]$completedCheckbox
        )
        try {
            if ($completedOperation.Error) {
                Write-WinUtilLog -Level "ERROR" -Component "Install" -Message "Get installed state failed: $($completedOperation.Error)"
                Write-Warning "Unable to get installed state: $($completedOperation.Error)"
                return
            }

            if ($completedCheckbox -eq "winget") {
                foreach ($checkboxName in $completedOperation.Checkboxes) {
                    if (-not $sync.selectedApps.Contains($checkboxName)) {
                        $sync.selectedApps.Add($checkboxName)
                    }
                }
                Reset-WPFCheckBoxes -checkboxfilterpattern "WPFInstall*"
            } else {
                foreach ($checkboxName in $completedOperation.Checkboxes) {
                    $sync.$checkboxName.ischecked = $True
                }
            }
        } finally {
            $sync.ProcessRunning = $false
            Set-WinUtilTaskbaritem -state "None"
        }
    }

    $sync.ProcessRunning = $true
    Set-WinUtilTaskbaritem -state "Indeterminate"
    try {
        Invoke-WPFRunspace -ParameterList @(
            ("managerPreference", $managerPreference),
            ("checkbox", $checkbox),
            ("operation", $operation),
            ("completeAction", $completeAction)
        ) -ScriptBlock {
            param (
                [string]$checkbox,
                [string]$managerPreference,
                [hashtable]$operation,
                [Action[hashtable, string]]$completeAction
            )
            try {
                if ($checkbox -eq "winget") {
                    switch ($managerPreference) {
                        "Choco" { $operation.Checkboxes = @(Invoke-WinUtilCurrentSystem -CheckBox "choco"); break }
                        "Winget" { $operation.Checkboxes = @(Invoke-WinUtilCurrentSystem -CheckBox $checkbox); break }
                    }
                } elseif ($checkbox -eq "tweaks") {
                    $operation.Checkboxes = @(Invoke-WinUtilCurrentSystem -CheckBox $checkbox)
                }
            } catch {
                $operation.Error = $_.Exception.Message
            } finally {
                $sync.Form.Dispatcher.BeginInvoke($completeAction, [object[]]@($operation, $checkbox)) | Out-Null
            }
        }
    } catch {
        $operation.Error = $_.Exception.Message
        $completeAction.Invoke($operation, $checkbox)
    }
}
