function Invoke-WPFOOSU {
    try {
        Write-Host "Downloading O&O ShutUp10..."
        Invoke-WebRequest -Uri https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe -OutFile "$winutildir\ooshutup10.exe"
        Write-Host "Starting O&O ShutUp10..."
        Start-Process -FilePath "$winutildir\ooshutup10.exe"
    } catch {
        Write-Error "Couldn't download O&O ShutUp10. Please make sure you have an active Internet connection."
    }
}
