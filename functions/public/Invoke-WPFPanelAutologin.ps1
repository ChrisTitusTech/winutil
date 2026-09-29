function Invoke-WPFPanelAutologin {
    $autologonPath = Join-Path $sync.winutildir "autologin.exe"
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile $autologonPath
    Start-Process -FilePath $autologonPath -ArgumentList /accepteula
}
