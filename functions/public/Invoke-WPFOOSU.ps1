function Invoke-WPFOOSU {
    Start-WinUtilJob -Name "OOSU" -Description "Downloading O&O ShutUp10++" -Parameters @{
        DownloadPath = Join-Path $sync.winutildir "ooshutup10.exe"
    } -ScriptBlock {
        param($DownloadPath)

        Write-WinUtilLog -Component "OOSU" -Message "Downloading O&O ShutUp10++."

        Save-WinUtilFile -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -DestinationPath $DownloadPath -ProgressCallback {
            param($percent)
            Write-WinUtilJobProgress -Status "Downloading O&O ShutUp10++ ($percent%)" -Percent $percent
        }

        Write-WinUtilJobProgress -Status "Launching O&O ShutUp10++" -Percent 100
        Start-Process -FilePath $DownloadPath
        Write-WinUtilLog -Component "OOSU" -Message "O&O ShutUp10++ launched."
    }
}
