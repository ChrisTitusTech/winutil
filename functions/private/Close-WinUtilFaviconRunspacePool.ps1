function Close-WinUtilFaviconRunspacePool {
    <#
        .SYNOPSIS
            Stops favicon work and disposes its timer, operations, circuit breaker, and runspace pool.
    #>
    if ($null -eq $sync) {
        return
    }

    if ($sync.FaviconCircuitBreaker) {
        $sync.FaviconCircuitBreaker.Cancel()
    }

    if ($sync.FaviconTimer) {
        $sync.FaviconTimer.Stop()
        $sync.Remove("FaviconTimer")
    }

    if ($sync.ContainsKey("FaviconQueue") -and $null -ne $sync.FaviconQueue) {
        $sync.FaviconQueue.Clear()
        $sync.Remove("FaviconQueue")
    }

    if ($sync.FaviconOperations) {
        foreach ($operation in @($sync.FaviconOperations.Values)) {
            try {
                $operation.PowerShell.Stop()
            } catch {
            }
            try {
                $operation.PowerShell.Dispose()
            } catch {
            }
        }
        $sync.FaviconOperations.Clear()
    }

    if ($sync.FaviconRunspace) {
        try {
            if ($sync.FaviconRunspace.RunspacePoolStateInfo.State -notin @(
                [System.Management.Automation.Runspaces.RunspacePoolState]::Closed,
                [System.Management.Automation.Runspaces.RunspacePoolState]::Closing,
                [System.Management.Automation.Runspaces.RunspacePoolState]::Broken
            )) {
                $sync.FaviconRunspace.Close()
            }
        } finally {
            $sync.FaviconRunspace.Dispose()
            $sync.Remove("FaviconRunspace")
        }
    }

    if ($sync.FaviconCircuitBreaker) {
        $sync.FaviconCircuitBreaker.Dispose()
        $sync.Remove("FaviconCircuitBreaker")
    }
}
