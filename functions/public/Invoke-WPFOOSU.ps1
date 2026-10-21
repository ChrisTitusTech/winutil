function Invoke-WPFOOSU {
    Start-WinUtilJob -Name "OOSU" -Description "Downloading O&O ShutUp10++" -Parameters @{
        DownloadPath = Join-Path $sync.winutildir "ooshutup10.exe"
    } -ScriptBlock {
        param($DownloadPath)

        Write-WinUtilLog -Component "OOSU" -Message "Downloading O&O ShutUp10++."

        Save-WinUtilFile -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -DestinationPath $DownloadPath -ProgressCallback {
            param($percent, $totalBytes)

            # The server may omit Content-Length, in which case only the percentage is known
            $progress = if ($totalBytes -gt 0) {
                "$percent% of $([math]::Round($totalBytes / 1MB)) MB"
            } else {
                "$percent%"
            }
            Step-WinUtilJob -Status "Downloading O&O ShutUp10++ ($progress)" -Percent $percent
        }

        Step-WinUtilJob -Status "Launching O&O ShutUp10++" -Percent 100
        Start-Process -FilePath $DownloadPath
        Write-WinUtilLog -Component "OOSU" -Message "O&O ShutUp10++ launched."
    }
}
