function Close-WinUtilRunspacePool {
    <#
        .SYNOPSIS
            Stops anything still running and closes the worker pool

        .DESCRIPTION
            Closing the pool with work still in it is what produced an unhandled
            InvalidRunspaceStateException: a queued instance starts on a runspace that is already
            closing, throws on a thread pool thread, and takes the process down. Whatever is in
            flight is therefore asked to stop, and waited for, before the pool is closed.
    #>
    param(
        [int]$StopTimeoutSeconds = 15,

        # Leaves ShuttingDown clear: nothing resets it, so setting it here would refuse every
        # later action for the rest of the session
        [switch]$Recycle
    )

    if ($null -eq $sync -or -not $sync.ContainsKey("runspace") -or $null -eq $sync.runspace) {
        return
    }

    # Set before stopping, so nothing that is winding down queues fresh work behind us
    if (-not $Recycle) {
        $sync.ShuttingDown = $true
    }

    try {
        Stop-WinUtilActiveWork -TimeoutSeconds $StopTimeoutSeconds | Out-Null
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not stop running work cleanly: $($_.Exception.Message)"
    }

    try {
        if ($sync.runspace.RunspacePoolStateInfo.State -notin @(
            [System.Management.Automation.Runspaces.RunspacePoolState]::Closed,
            [System.Management.Automation.Runspaces.RunspacePoolState]::Closing,
            [System.Management.Automation.Runspaces.RunspacePoolState]::Broken
        )) {
            $sync.runspace.Close()
        }
    } catch {
        # A pool that will not close cleanly must not stop the window from closing
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Worker pool did not close cleanly: $($_.Exception.Message)"
    } finally {
        try { $sync.runspace.Dispose() } catch { }
        $sync.Remove("runspace")
        if ($sync.ActiveShells) { $sync.ActiveShells.Clear() }
    }
}
