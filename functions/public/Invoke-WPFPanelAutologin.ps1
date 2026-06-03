function Invoke-WPFPanelAutologin {
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile "$Env:Temp\autologin.exe"
    Start-Process -FilePath "$Env:Temp\autologin.exe" -ArgumentList /accepteula
}
