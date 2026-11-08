function Invoke-WPFPanelAutologin {
    $autologonPath = Join-Path $sync.winutildir "autologin.exe"
    Invoke-WebRequest -Uri https://live.sysinternals.com/Autologon.exe -OutFile $autologonPath

    $signature = Get-AuthenticodeSignature -FilePath $autologonPath
    if ($signature.Status -ne 'Valid') {
        throw "Autologon download failed Authenticode verification ($($signature.Status))."
    }

    Start-Process -FilePath $autologonPath -ArgumentList /accepteula
}
