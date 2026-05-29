function Invoke-WPFOOSU {
    try {
        $ProgressPreference = 'SilentlyContinue'

        Invoke-WebRequest -Uri https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe -OutFile "$Env:Temp\ooshutup10.exe"
        Start-Process -FilePath "$Env:Temp\ooshutup10.exe"

        $ProgressPreference = 'Continue'
    } catch {
        Write-Error "Couldn't download ooshutup10 make sure you have a active internet connection"
    }
}
