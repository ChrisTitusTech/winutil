function Close-WinUtilFaviconRunspacePool {
    if ($null -eq $sync) {
        return
    }

    if ($sync.FaviconTimer) {
        $sync.FaviconTimer.Stop()
        $sync.Remove("FaviconTimer")
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
}
