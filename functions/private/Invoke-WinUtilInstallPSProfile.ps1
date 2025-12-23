function Invoke-WinUtilInstallPSProfile {
    Start-Process powershell -ArgumentList '-Command "irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex"'
}
