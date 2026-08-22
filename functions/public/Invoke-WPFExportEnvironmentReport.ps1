function Invoke-WPFExportEnvironmentReport {
    <#
    .SYNOPSIS
        Exports an allowlisted, read-only environment report as JSON, with an optional bundle of
        recent WinUtil logs.
    #>

    try {
        $includeLogs = [System.Windows.MessageBox]::Show(
            $sync.Form,
            "Also include the last 7 days of WinUtil logs? This can help maintainers troubleshoot an issue.",
            "Environment Report", "YesNo", "Question") -eq "Yes"

        Add-Type -AssemblyName System.Windows.Forms
        $dialog = [System.Windows.Forms.SaveFileDialog]::new()
        $dialog.Title = "Export Environment Report"
        $dialog.Filter = "JSON files (*.json)|*.json"
        $dialog.FileName = "WinUtilEnvironmentReport_$(Get-Date -Format 'yyyyMMdd').json"
        $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        $jsonPath = $dialog.FileName
        $logsPath = Get-WinUtilEnvironmentReportLogsPath -JsonPath $jsonPath

        # SaveFileDialog's own overwrite prompt only covers $jsonPath. $logsPath is derived and never
        # shown to the user, so a same-day re-export would otherwise silently replace it.
        if ($includeLogs -and (Test-Path $logsPath)) {
            $includeLogs = [System.Windows.MessageBox]::Show(
                $sync.Form,
                "A logs file already exists at:`n$logsPath`n`nReplace it?",
                "Environment Report", "YesNo", "Warning") -eq "Yes"
        }

        Write-WinUtilLog -Component "EnvironmentReport" -Message "Environment report export started."
        Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Exporting environment report..." -Percent 0

        # Registry reads across every tweak/toggle and the log bundle's file read add up to a
        # couple of seconds. This handler runs directly on the WPF dispatcher thread (wired from
        # the Settings menu), so the collection and write happen in a background runspace to avoid
        # freezing the window.
        Invoke-WPFRunspace -ParameterList @(("JsonPath", $jsonPath), ("LogsPath", $logsPath), ("IncludeLogs", $includeLogs)) -ScriptBlock {
            param($JsonPath, $LogsPath, $IncludeLogs)

            try {
                $report = Get-WinUtilEnvironmentReport
                Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Writing environment report..." -Percent 60
                $json = $report | ConvertTo-Json -Depth 6
                [System.IO.File]::WriteAllText($JsonPath, $json, [System.Text.UTF8Encoding]::new($false))

                if ($IncludeLogs) {
                    $logs = Get-WinUtilRecentLogs
                    [System.IO.File]::WriteAllText($LogsPath, $logs, [System.Text.UTF8Encoding]::new($false))
                }

                Write-WinUtilLog -Component "EnvironmentReport" -Message "Environment report exported to $JsonPath."
                Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Environment export completed" -Percent 100
                Invoke-WPFUIThread { Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" }
            } catch {
                # No MessageBox here: it would hop through Invoke-WPFUIThread/Dispatcher.Invoke from
                # this background thread, the combination that can stall/freeze the UI.
                # The progress label, taskbar overlay, and log line carry the failure instead.
                Write-WinUtilLog -Component "EnvironmentReport" -Level "ERROR" -Message "Environment report export failed: $($_.Exception.Message)"
                Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Environment export failed: $($_.Exception.Message)" -Percent 100
                Invoke-WPFUIThread { Set-WinUtilTaskbaritem -state "Error" -overlay "warning" }
            }

            # This is wired from a Settings-menu item, not a feature.json Button, so it never
            # benefits from Invoke-WPFButton's implicit "clear the progress indicator on the next
            # click" reset. Hide it explicitly instead, after a brief pause so the completed/failed
            # label is actually visible.
            Start-Sleep -Seconds 3
            Set-WinUtilTweaksProgressIndicator -Visible $false
        } | Out-Null
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "ERROR" -Message "Environment report export failed: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show(
            $sync.Form,
            "The environment report could not be exported. $($_.Exception.Message)",
            "Environment Report",
            "OK",
            "None"
        ) | Out-Null
    }
}
