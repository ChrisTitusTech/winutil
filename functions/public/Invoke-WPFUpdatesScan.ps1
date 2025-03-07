function Invoke-WPFUpdatesScan {
    $sync["WPFScanUpdates"].IsEnabled = $false
    $sync["WPFUpdateSelectedInstall"].IsEnabled = $false
    $sync["WPFUpdateAllInstall"].IsEnabled = $false
    Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo"
    Invoke-WPFRunspace -DebugPreference $DebugPreference -ScriptBlock {
        # Check if the PSWindowsUpdate module is installed
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            try {
                Write-Host "PSWindowsUpdate module not found. Attempting to install..."
                Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
                Write-Host "PSWindowsUpdate module installed successfully."
            }
            catch {
                Write-Error "Failed to install PSWindowsUpdate module: $_"
                $sync.form.Dispatcher.Invoke([action] { $sync["WPFScanUpdates"].IsEnabled = $true })
                return
            }
        }

        # Import the module
        try {
            Import-Module PSWindowsUpdate -ErrorAction Stop
            Write-Host "PSWindowsUpdate module imported successfully."
        }
        catch {
            Write-Error "Failed to import PSWindowsUpdate module: $_"
            $sync.form.Dispatcher.Invoke([action] { $sync["WPFScanUpdates"].IsEnabled = $true })
            return
        }

        try {
            $sync.form.Dispatcher.Invoke([action] { $sync["WPFUpdatesList"].Items.Clear() })
            Write-Host "Scanning for Windows updates..."
            $updates = Get-WindowsUpdate -ErrorAction Stop
            Write-Host "Found $($updates.Count) updates."

            $sync.form.Dispatcher.Invoke([action] {
                foreach ($update in $updates) {
                    $item = New-Object PSObject -Property @{
                        LongTitle = $update.Title
                        ComputerName = $update.ComputerName
                        KB = $update.KB
                        Size = $update.Size
                        Title = $update.Title -replace '\s*\(KB\d+\)', '' -replace '\s*KB\d+\b', '' # Remove KB number from title, first in parentheses, then standalone
                        Status = "Not Installed"
                    }
                    $Computers = $item | Select-Object -ExpandProperty ComputerName -Unique
                    $sync["WPFUpdatesList"].Items.Add($item)
                }
                if ($Computers.Count -gt 1) {
                    $sync["WPFUpdatesList"].Columns[0].Visibility = "Visible"
                } else {
                    Write-Debug "Hiding ComputerName column, only $item.ComputerName"
                    $sync["WPFUpdatesList"].Columns[0].Visibility = "Collapsed"
                }
            })
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
        } catch {
            Write-Error "Error scanning for updates: $_"
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
        }
    }
    $sync["WPFScanUpdates"].IsEnabled = $false
    $sync["WPFUpdateSelectedInstall"].IsEnabled = $false
    $sync["WPFUpdateAllInstall"].IsEnabled = $false
}
