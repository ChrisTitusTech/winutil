function Invoke-WinUtilInstallPSProfile {
    if (-not (Get-Command wt)) {
        Write-Host "Windows Terminal not found installing..."
        Install-WinUtilWinget
        winget install Microsoft.WindowsTerminal --source winget --silent
    }

    if (-not (Get-Command pwsh)) {
        Write-Host "Powershell 7 not found installing..."
        Install-WinUtilWinget
        winget install Microsoft.PowerShell --source winget --silent
    }

    wt new-tab pwsh -NoExit -Command "irm https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1 | iex \; if (Test-Path `$PROFILE) { (Get-Content `$PROFILE -Raw) -replace 'Invoke-RestMethod https://christitus.com/win \| Invoke-Expression', '& ([ScriptBlock]::Create((Invoke-RestMethod https://christitus.com/win))) `@args' -replace 'Invoke-RestMethod https://christitus.com/windev \| Invoke-Expression', '& ([ScriptBlock]::Create((Invoke-RestMethod https://christitus.com/windev))) `@args }; function winutil-dev { & ([ScriptBlock]::Create((Invoke-RestMethod https://christitus.com/windev))) `@args' | Set-Content `$PROFILE }"
}
