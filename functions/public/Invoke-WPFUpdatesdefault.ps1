function Invoke-WPFUpdatesdefault {
    <#

    .SYNOPSIS
        Undo what other windows update tweaks do

    #>

    Write-Host "Enabling driver offering through Windows Update"
    Remove-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Recurse -Force

    Write-Host "Starting and enabling Windows Updates service"

    Start-Service usosvc
    Set-Service usosvc -StartupType Automatic

    Write-Host "==================================================="
    Write-Host "---  Windows Local Policies Reset to Default   ---"
    Write-Host "==================================================="
}
