function Invoke-WPFFixesDesktopIconFixer {
    Remove-Item -Path "$Env:LocalAppData\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$Env:LocalAppData\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$Env:LocalAppData\IconCache.db" -Force -ErrorAction SilentlyContinue

    taskkill.exe /F /IM explorer.exe | Out-Null
    Start-Process -FilePath "explorer.exe"

    Write-Host "==> Desktop icon cache rebuilt successfully"
}
