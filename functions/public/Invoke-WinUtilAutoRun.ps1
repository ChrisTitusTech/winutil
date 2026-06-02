function Invoke-WinUtilAutoRun {
    <#

    .SYNOPSIS
        Runs Install, Tweaks, and Features with optional UI invocation.
    #>

    function BusyWait ($RunspaceJob) {
        if ($RunspaceJob -and $RunspaceJob.Handle) {
            $RunspaceJob.PowerShell.EndInvoke($RunspaceJob.Handle)
            $RunspaceJob.PowerShell.Dispose()
            return
        }

        while ($sync.ProcessRunning) {
            Start-Sleep -Milliseconds 100
        }
    }

    if ($sync.selectedTweaks.Count -gt 0) {
        Write-Host "Applying tweaks..."
        $job = Invoke-WPFtweaksbutton
        BusyWait $job
    }

    if ($sync.selectedFeatures.Count -gt 0) {
        Write-Host "Applying features..."
        $job = Invoke-WPFFeatureInstall
        BusyWait $job
    }

    if ($sync.selectedApps.Count -gt 0) {
        Write-Host "Installing applications..."
        $job = Invoke-WPFInstall
        BusyWait $job
    }

    Write-Host "Done."
}
