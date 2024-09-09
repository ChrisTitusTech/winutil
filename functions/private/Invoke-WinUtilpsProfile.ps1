function Invoke-WinUtilpsProfile {
    <#
    .SYNOPSIS
        Installs & applies the CTT Powershell Profile
    #>

    if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $url = "https://raw.githubusercontent.com/ChrisTitusTech/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
            $oldhash = Get-FileHash $PROFILE -ErrorAction SilentlyContinue
            Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
            $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
            if ($newhash.Hash -ne $oldhash.Hash) {
                Invoke-WPFRunspace -DebugPreference $DebugPreference -ScriptBlock {
                    write-host "===> Updating Profile.. <===" -ForegroundColor Yellow
                    Start-Process -FilePath "pwsh" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"Invoke-Expression (Invoke-WebRequest `'https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1`')`"" -WindowStyle Hidden -Wait
                    Write-Host "Profile has been updated. Please restart your shell to reflect changes!" -ForegroundColor Magenta
                    write-host "===> Finished <===" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Profile is up to date" -ForegroundColor Green
            }
        }
        else {
            write-host "Powershell 5 is running, but Powershell 7 is installed." -ForegroundColor Red
        }
    }
    else {
        write-host "Powershell 7 is not installed." -ForegroundColor Red
    }
}
