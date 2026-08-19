function Initialize-WinUtilFaviconRunspacePool {
    <#
        .SYNOPSIS
            Creates or returns the dedicated runspace pool used for favicon downloads.
        .DESCRIPTION
            Uses the machine's available logical processor count, with a minimum of one
            worker. The pool remains dedicated to favicon downloads so this work stays
            isolated from other WinUtil runspaces.
    #>
    if ($sync.FaviconRunspace -and $sync.FaviconRunspace.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
        return $sync.FaviconRunspace
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

    $maxThreads = [Environment]::ProcessorCount
    $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

    $sync.FaviconRunspace = [runspacefactory]::CreateRunspacePool(
        1,
        $maxThreads,
        $initialSessionState,
        $Host
    )
    $sync.FaviconRunspace.Open()
    return $sync.FaviconRunspace
}
