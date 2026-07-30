function Initialize-WinUtilFaviconRunspacePool {
    if ($sync.FaviconRunspace -and $sync.FaviconRunspace.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
        return $sync.FaviconRunspace
    }

    if ($sync.FaviconRunspace) {
        Close-WinUtilFaviconRunspacePool
    }

    $halfProcessors = [Math]::Floor([Environment]::ProcessorCount / 2)
    $maxThreads = [Math]::Max($halfProcessors, 2)
    $maxThreads = [Math]::Min($maxThreads, 8)
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
