function Invoke-WinUtilAutoRun {
    <#

    .SYNOPSIS
        Runs Install, Tweaks, and Features with optional UI invocation.
    #>

    function BusyWait {
        while ($sync.ProcessRunning) {
            Start-Sleep -Seconds 1
        }
    }

    Write-Host "Applying tweaks..."
    Invoke-WPFtweaksbutton
    BusyWait

    Write-Host "Applying features..."
    Invoke-WPFFeatureInstall
    BusyWait

    Write-Host "Installing applications..."
    Invoke-WPFInstall
    BusyWait

    Write-Host "Done."
}
