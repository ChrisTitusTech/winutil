function Invoke-WinUtilInstallPSProfile {

    if (Test-Path $Profile) {
        Rename-Item $Profile -NewName ($Profile + '.bak') -Force
    }

    try {
        Start-Process pwsh -ArgumentList '-Command "irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex"'
    }
    catch {
        Write-Host "pwsh is not installed... Installing pwsh..."
        winget install pwsh --source winget
        Start-Process pwsh -ArgumentList '-Command "irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex"'
    }
}
