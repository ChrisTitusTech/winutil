function Invoke-WPFExportEnvironmentReport {
    <#
    .SYNOPSIS
        Exports an allowlisted, read-only environment report as JSON.
    #>

    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = [System.Windows.Forms.SaveFileDialog]::new()
        $dialog.Title = "Export Environment Report"
        $dialog.Filter = "JSON files (*.json)|*.json"
        $dialog.FileName = "WinUtilEnvironmentReport_$(Get-Date -Format 'yyyyMMdd').json"
        $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        $report = Get-WinUtilEnvironmentReport
        $json = $report | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($dialog.FileName, $json, [System.Text.UTF8Encoding]::new($false))

        Write-WinUtilLog -Component "EnvironmentReport" -Message "Environment report exported."
        [System.Windows.MessageBox]::Show(
            "The environment report was exported successfully.",
            "Environment Report",
            "OK",
            "Information"
        ) | Out-Null
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "ERROR" -Message "Environment report export failed: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show(
            "The environment report could not be exported. $($_.Exception.Message)",
            "Environment Report",
            "OK",
            "Error"
        ) | Out-Null
    }
}
