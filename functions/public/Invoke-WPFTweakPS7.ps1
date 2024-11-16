function Invoke-WPFTweakPS7 {
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
        "PS7" {
            if (Test-Path -Path "$env:ProgramFiles\PowerShell\7") {
                Write-Host "Powershell 7 is already installed."
            } else {
                Write-Host "Installing Powershell 7..."
                Install-WinUtilProgramWinget -Action Install -Programs @("Microsoft.PowerShell")
            }
            $targetTerminalName = "PowerShell"
            $targetCommandLine = "C:\Program Files\PowerShell\7\pwsh.exe"
        }
        "PS5" {
            $targetTerminalName = "Windows PowerShell"
            $targetCommandLine = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        }
    }
    # Check if the Windows Terminal is installed and return if not (Prerequisite for the following code)
    if (-not (Get-Command "wt" -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Terminal not installed. Skipping Terminal preference"
        return
    }
    # Check if the Windows Terminal settings.json file exists and return if not (Prerequisite for the following code)
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path -Path $settingsPath)) {
        Write-Host "Windows Terminal Settings file not found at $settingsPath"
        return
    }

    Write-Host "Settings file found."
    $settingsContent = Get-Content -Path $settingsPath | ConvertFrom-Json
    $targetProfile = $settingsContent.profiles.list | Where-Object { $_.name -eq $targetTerminalName }
    if ($targetProfile) {
        $settingsContent.defaultProfile = $targetProfile.guid
        $targetProfile.commandline = $targetCommandLine
        $updatedSettings = $settingsContent | ConvertTo-Json -Depth 100
        Set-Content -Path $settingsPath -Value $updatedSettings
        Write-Host "Default profile updated to " -NoNewline
        Write-Host "$targetTerminalName " -ForegroundColor White -NoNewline
        Write-Host "with command line: $targetCommandLine"
    } else {
        Write-Host "No $targetTerminalName profile found in Windows Terminal settings using the name attribute."
    }
}

