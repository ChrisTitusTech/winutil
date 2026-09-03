function Invoke-WPFExportEnvironmentReport {
    <#
    .SYNOPSIS
        Exports an allowlisted, read-only environment report as JSON, with an optional bundle of
        recent WinUtil logs.
    #>

    try {
        $includeLogs = (Show-WinUtilMessage `
            -Message "Also include the last 7 days of WinUtil logs? The companion file contains raw logs and may include local paths, commands, and error details. Review it before sharing." `
            -Title "Environment Report" -Button "YesNo" -Icon "Question") -eq "Yes"

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

        # SaveFileDialog's own overwrite prompt only covers $jsonPath. A derived companion from a
        # previous export must neither be silently replaced nor left looking like it belongs to new JSON.
        if (Test-Path -LiteralPath $logsPath) {
            if (-not $includeLogs) {
                Show-WinUtilMessage `
                    -Message "A logs file already exists at:`n$logsPath`n`nChoose another report filename or include and replace the existing logs." `
                    -Title "Environment Report" -Button "OK" -Icon "Warning" | Out-Null
                return
            }

            $replaceLogs = (Show-WinUtilMessage `
                -Message "A logs file already exists at:`n$logsPath`n`nReplace it?" `
                -Title "Environment Report" -Button "YesNo" -Icon "Warning") -eq "Yes"
            if (-not $replaceLogs) {
                return
            }
        }

        # Registry reads across every tweak/toggle and the log bundle's file read add up to a
        # couple of seconds, so the job layer keeps the Settings handler responsive and owns the
        # progress, taskbar state, logging, and error reporting.
        Start-WinUtilJob -Name "EnvironmentReport" -Description "Exporting environment report" -Parameters @{
            JsonPath = $jsonPath
            LogsPath = $logsPath
            IncludeLogs = $includeLogs
        } -ScriptBlock {
            param($JsonPath, $LogsPath, $IncludeLogs)

            Step-WinUtilJob -Status "Collecting environment report" -Percent 10
            $report = Get-WinUtilEnvironmentReport
            $json = $report | ConvertTo-Json -Depth 6

            if ($IncludeLogs) {
                Step-WinUtilJob -Status "Collecting recent WinUtil logs" -Percent 60
                $logs = Get-WinUtilRecentLogs
            }

            Step-WinUtilJob -Status "Writing environment export" -Percent 80
            Write-WinUtilEnvironmentReportExport -JsonPath $JsonPath -Json $json `
                -LogsPath $LogsPath -Logs $logs -IncludeLogs:$IncludeLogs

            Write-WinUtilLog -Component "EnvironmentReport" -Message "Environment report exported to $JsonPath."
            Step-WinUtilJob -Status "Environment export completed" -Percent 100
        }
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "ERROR" -Message "Environment report export failed: $($_.Exception.Message)"
        Show-WinUtilMessage -Message "The environment report could not be exported. $($_.Exception.Message)" `
            -Title "Environment Report" -Button "OK" -Icon "None" | Out-Null
    }
}
