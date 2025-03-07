function Invoke-WPFUpdateMGMT {
    param (
        [switch]$Selected,
        [switch]$All
    )

    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })

    if ($All) {
        Write-Host "Installing all available updates ..."
        Invoke-WPFRunspace -ArgumentList $sync["WPFUpdateVerbose"].IsChecked -DebugPreference $DebugPreference -ScriptBlock {
            param ($WPFUpdateVerbose)
            if ($WPFUpdateVerbose) {
                Install-WindowsUpdate -Verbose -Confirm:$false -IgnoreReboot:$true -IgnoreRebootRequired:$true
            } else {
                Install-WindowsUpdate -Confirm:$false -IgnoreReboot:$true -IgnoreRebootRequired:$true
            }
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
            Write-Host "All Update Processes Completed"
            #catch $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
        }
    } elseif (($Selected) -and ($sync["WPFUpdatesList"].SelectedItems.Count -gt 0)) {
        write-host "Installing selected updates..."
        $selectedUpdates = $sync["WPFUpdatesList"].SelectedItems | ForEach-Object {
            [PSCustomObject]@{
                ComputerName = $_.ComputerName
                Title        = $_.LongTitle
                KB           = $_.KB
                Size         = $_.Size
            }
        }
        Invoke-WPFRunspace -ParameterList @(("selectedUpdates", $selectedUpdates), ("WPFUpdateVerbose", $sync["WPFUpdateVerbose"].IsChecked)) -DebugPreference $DebugPreference -ScriptBlock {
            param ($selectedUpdates, $WPFUpdateVerbose)
            foreach ($update in $selectedUpdates) {
                Write-Host "Installing update $($update.Title) on $($update.ComputerName)"
                if ($WPFUpdateVerbose) {
                    Get-WindowsUpdate -ComputerName $update.ComputerName -Title $update.Title -Install -Confirm:$false -Verbose -IgnoreReboot:$true -IgnoreRebootRequired:$true
                } else {
                    Get-WindowsUpdate -ComputerName $update.ComputerName -Title $update.Title -Install -Confirm:$false -IgnoreReboot:$true -IgnoreRebootRequired:$true
                }
            }
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
            Write-Host "Selected Update Processes Completed"
            #catch $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
        }
    } else {
        Write-Host "No updates selected"
        return
    }
}
