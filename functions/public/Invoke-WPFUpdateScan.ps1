function Invoke-WPFUpdateHistoryToggle {
    <#
    .SYNOPSIS
        Toggles the visibility of the Windows update history and available updates.
    #>

    $showHistory = $sync["WPFShowUpdateHistory"].Content -eq "Show History"

    $sync["WPFShowUpdateHistory"].Content = if ($showHistory) { "Show available Updates" } else { "Show History" }
    $sync["HistoryGrid"].Visibility = if ($showHistory) { "Visible" } else { "Collapsed" }
    $sync["UpdatesGrid"].Visibility = if ($showHistory) { "Collapsed" } else { "Visible" }
}

function Invoke-WinUtilUpdateControls {
    <#
    .SYNOPSIS
        Disables or enables the update controls based on the specified state.

    .PARAMETER state
        The state to set the controls to.
    #>

    param (
        [boolean]$state
    )

    $sync["WPFScanUpdates"].IsEnabled = $state
    $sync["WPFUpdateScanHistory"].IsEnabled = $state
    $sync["WPFUpdateSelectedInstall"].IsEnabled = $state
    $sync["WPFUpdateAllInstall"].IsEnabled = $state
}


function Invoke-WPFUpdateScan {
    <#
    .SYNOPSIS
        Scans for Windows updates and history and builds the DataGrids for the UI.

    .PARAMETER type
        The type of scan to perform.

    #>

    param (
        [string]$type
    )

    Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo"
    Invoke-WinUtilUpdateControls -state $false

    Invoke-WPFRunspace -ArgumentList $type -DebugPreference $DebugPreference -ScriptBlock {
        param ($type)
        try {
            Invoke-WinUtilInitializeModule -module "PSWindowsUpdate"
            switch ($type) {
                "updates" {
                    $sync.form.Dispatcher.Invoke([action] { $sync["WPFUpdatesList"].ItemsSource = $null })
                    Write-Host "Scanning for Windows updates..."
                    $updates = Get-WindowsUpdate -ErrorAction SilentlyContinue
                    Write-Host "Found $($updates.Count) updates."

                    # Build the list of items first
                    $items = foreach ($update in $updates) {
                        [PSCustomObject]@{
                            LongTitle    = $update.Title
                            ComputerName = $update.ComputerName
                            KB           = $update.KB
                            Size         = $update.Size
                            Title        = $update.Title -replace '\s*\(KB\d+\)', '' -replace '\s*KB\d+\b', ''
                            Status       = "Not Installed"
                        }
                    }

                    $Computers = $updates.ComputerName | Select-Object -Unique

                    # Update the DataGrid at once
                    $sync.form.Dispatcher.Invoke([action] {
                        $sync["WPFUpdatesList"].ItemsSource = $items
                        $sync["WPFUpdatesList"].Columns[0].Visibility = if ($Computers.Count -gt 1) { "Visible" } else { "Collapsed" }
                    })
                }
                "history" {
                    $sync.form.Dispatcher.Invoke([action] { $sync["WPFUpdateHistory"].ItemsSource = $null })
                    Write-Host "Scanning for Windows update history..."
                    $history = Get-WUHistory -Last 50 -ErrorAction Stop
                    if (!$history) {
                        Write-Host "No update history available."
                        return
                    }

                    # Build the list of history items first
                    $items = foreach ($update in $history) {
                        [PSCustomObject]@{
                            ComputerName = $update.ComputerName
                            Result       = $update.Result
                            Title        = $update.Title -replace '\s*\(KB\d+\)', '' -replace '\s*KB\d+\b', ''
                            KB           = $update.KB
                            Date         = $update.Date
                        }
                    }

                    $Computers = $history.ComputerName | Select-Object -Unique

                    # Update the DataGrid at once
                    $sync.form.Dispatcher.Invoke([action] {
                        $sync["WPFUpdateHistory"].ItemsSource = $items
                        $sync["WPFUpdateHistory"].Columns[0].Visibility = if ($Computers.Count -gt 1) { "Visible" } else { "Collapsed" }
                    })
                    Write-Host "Scanning for Windows update history completed"
                }
            }

            $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
        }
        catch {
            $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
            Write-Host "Error during scan: $_" -ForegroundColor Red
        } finally {
            $sync.form.Dispatcher.Invoke([action] { Invoke-WinUtilUpdateControls -state $true })
        }
    }
}
