function Invoke-WPFUpdateScanHistory {
    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
    $sync["WPFUpdateHistory"].Items.Clear()
    Invoke-WPFRunspace -DebugPreference $DebugPreference -ScriptBlock {
        write-host "Scanning for Windows update history..."
        $UpdateHistory = Get-WUHistory -Last 50 -ErrorAction SilentlyContinue
        if ($UpdateHistory) {
            foreach ($update in $UpdateHistory) {
                $item = New-Object PSObject -Property @{
                    ComputerName = $update.ComputerName
                    Result       = $update.Result
                    Title        = $update.Title -replace '\s*\(KB\d+\)', '' -replace '\s*KB\d+\b', '' # Remove KB number from title, first in parentheses, then standalone
                    KB           = $update.KB
                    Date         = $update.Date
                }
                $Computers = $item | Select-Object -ExpandProperty ComputerName -Unique
                $sync.form.Dispatcher.Invoke([action] {
                    $sync["WPFUpdateHistory"].Items.Add($item)
                    if ($item.Result -eq "Succeeded") {
                        # does not work : $sync["WPFUpdateHistory"].Items[$sync["WPFUpdateHistory"].Items.Count - 1].Foreground = "Green"
                        #write-host "$($item.Title) was successful"
                    }
                    elseif ($item.Result -eq "Failed") {
                        # does not work : $sync["WPFUpdateHistory"].Items[$sync["WPFUpdateHistory"].Items.Count - 1].Foreground = "Red"
                        #write-host "$($item.Title) failed"
                    }
                })
            }
            write-host "Found $($UpdateHistory.Count) updates."
            $sync.form.Dispatcher.Invoke([action] {
                if ($Computers.Count -gt 1) {
                    $sync["WPFUpdateHistory"].Columns[0].Visibility = "Visible"
                }
                else {
                    Write-Debug "Hiding ComputerName column, only $item.ComputerName"
                    $sync["WPFUpdateHistory"].Columns[0].Visibility = "Collapsed"
                }
            })
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
            #catch $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -overlay "warning" })
        }
        else {
            $sync.form.Dispatcher.Invoke([action] {
                $sync["WPFUpdateHistory"].Items.Clear()
            })
            Write-Host "No update history available."
        }
    }
}
