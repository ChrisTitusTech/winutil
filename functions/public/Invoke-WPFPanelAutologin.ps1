function Invoke-WPFPanelAutologin {
    $autologonPath = Join-Path $sync.winutildir "autologin.exe"
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile $autologonPath -UseBasicParsing -TimeoutSec 120
    Assert-WinUtilFileSignature -LiteralPath $autologonPath -Publisher "Microsoft Corporation"
    Start-Process -FilePath $autologonPath -ArgumentList /accepteula
}
