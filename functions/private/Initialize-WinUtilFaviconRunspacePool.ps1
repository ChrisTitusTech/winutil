function Initialize-WinUtilFaviconRunspacePool {
    <#
        .SYNOPSIS
            Creates or returns the dedicated runspace pool used for favicon downloads.
        .DESCRIPTION
            Uses half the available logical processors while keeping concurrency between
            two and eight workers so favicon requests remain responsive without creating
            an excessive burst of connections.
    #>
    if ($sync.FaviconRunspace -and $sync.FaviconRunspace.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
        return $sync.FaviconRunspace
    }

    if ($sync.FaviconRunspace) {
        Close-WinUtilFaviconRunspacePool
    }

    $minimumWorkers = 2
    $maximumWorkers = 8
    $halfProcessors = [Math]::Floor([Environment]::ProcessorCount / 2)
    $maxThreads = [Math]::Max($halfProcessors, $minimumWorkers)
    $maxThreads = [Math]::Min($maxThreads, $maximumWorkers)
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
