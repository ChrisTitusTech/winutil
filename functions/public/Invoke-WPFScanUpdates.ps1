function Invoke-WPFScanUpdates {


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
            return
        }

        try {
            Write-Host "Clearing updates list..."
            $sync.form.Dispatcher.Invoke([action] { $sync["WPFUpdatesList"].Items.Clear() })
            Write-Host "Scanning for Windows updates..."
            $updates = Get-WindowsUpdate -ErrorAction Stop
            Write-Host "Found $($updates.Count) updates."

            $sync.form.Dispatcher.Invoke([action] {
                foreach ($update in $updates) {
                    $item = New-Object PSObject -Property @{
                        KB = $update.KB
                        Size = $update.Size
                        Title = $update.Title -replace '\s*\(KB\d+\)', '' -replace '\s*KB\d+\b', '' # Remove KB number from title, first in parentheses, then standalone
                        Status = "Not Installed"
                    }
                    $sync["WPFUpdatesList"].Items.Add($item)
                }
            })
        } catch {
            Write-Error "Error scanning for updates: $_"
        }
    }
}
