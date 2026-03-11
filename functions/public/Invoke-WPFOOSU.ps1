function Invoke-WPFOOSU {
    if (-not ((Test-NetConnection).PingSucceeded) {
        Write-Host "You must have a internet connect to download ooshutup10!" -ForegroundColor Red
        return
    }

    Invoke-WebRequest -Uri https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe -OutFile $Env:Temp\OOSU10.exe
    Start-Process $Env:Temp\OOSU10.exe
    }
}
