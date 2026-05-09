function Invoke-WinUtilUninstallPSProfile {
    Invoke-Expression (Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/uninstall.ps1)
}
