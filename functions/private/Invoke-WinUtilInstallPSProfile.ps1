function Invoke-WinUtilInstallPSProfile {

    if (Test-Path $Profile) {
        Rename-Item $Profile -NewName ($Profile + '.bak')
    }

    Start-Process pwsh -ArgumentList '-Command "irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex"'
}
