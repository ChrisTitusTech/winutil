function Install-WinUtilWinget {

    if (Get-Command -Name winget) {
        return
    }

    Write-Host "WinGet is not installed. Installing..." -ForegroundColor Red

    Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile "winget.msixbundle"
    Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip -OutFile "winget.zip"
    
    Expand-Archive "winget.zip"
    Add-AppxPackage -Path "winget.msixbundle" -DependencyPath "winget\x64\*"
    Remove-Item -Path "winget*" -Recurse
}
