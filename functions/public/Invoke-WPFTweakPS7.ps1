function Invoke-WPFTweakPS7{
        <#
    .SYNOPSIS
        This will edit the config file of the Windows Terminal Replacing the Powershell 5 to Powershell 7 and install Powershell 7 if necessary
    .PARAMETER action
        PS7:           Configures Powershell 7 to be the default Terminal
        PS5:           Configures Powershell 5 to be the default Terminal
    #>
    param (
        [ValidateSet("PS7", "PS5")]
        [string]$action
    )

    switch ($action) {
        "PS7"{
            if (Test-Path -Path "$env:ProgramFiles\PowerShell\7") {
                Write-Host "Powershell 7 is already installed."
            } else {
                Write-Host "Installing Powershell 7..."
                Install-WinUtilProgramWinget -ProgramsToInstall @(@{"winget"="Microsoft.PowerShell"})
            }
            $targetTerminalName = "PowerShell"
        }
        "PS5"{
            $targetTerminalName = "Windows PowerShell"
        }
    }

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path -Path $settingsPath) {
        Write-Host "Settings file found."
        $settingsContent = Get-Content -Path $settingsPath | ConvertFrom-Json
        $ps7Profile = $settingsContent.profiles.list | Where-Object { $_.name -eq $targetTerminalName }
        if ($ps7Profile) {
            $settingsContent.defaultProfile = $ps7Profile.guid
            $updatedSettings = $settingsContent | ConvertTo-Json -Depth 100
            Set-Content -Path $settingsPath -Value $updatedSettings
            Write-Host "Default profile updated to $targetTerminalName using the name attribute."
        } else {
            Write-Host "No PowerShell 7 profile found in Windows Terminal settings using the name attribute."
        }
    } else {
        Write-Host "Settings file not found at $settingsPath"
    }
}

