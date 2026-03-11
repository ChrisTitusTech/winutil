function Invoke-WPFOOSU {
    $Initial_ProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue" # Disables the Progress Bar to drasticly speed up Invoke-WebRequest

    if (-not ((Test-NetConnection).PingSucceeded)) {
        Write-Host "You must have an internet connection to download ooshutup10!" -ForegroundColor Red
        return
    }

    Invoke-WebRequest -Uri https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe -OutFile $Env:Temp\OOSU10.exe
    Start-Process $Env:Temp\OOSU10.exe

    $ProgressPreference = $Initial_ProgressPreference
}
