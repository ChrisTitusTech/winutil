function Invoke-WinUtilUninstallPSProfile {
    Invoke-Expression (Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/blob/main/uninstall.ps1)
}
