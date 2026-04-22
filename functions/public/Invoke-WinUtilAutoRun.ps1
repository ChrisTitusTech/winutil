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

    if ($sync.selectedTweaks.Count -gt 0) {
      Write-Host "Applying tweaks..."
      Invoke-WPFtweaksbutton
      BusyWait
    }

    if ($selectedFeatures.Count -eq 0) {
        Write-Host "Applying features..."
        Invoke-WPFFeatureInstall
        BusyWait
    }

    if ($PackagesToInstall.Count -eq 0) {
        Write-Host "Installing applications..."
        Invoke-WPFInstall
        BusyWait
    }

    Write-Host "Done."
}
