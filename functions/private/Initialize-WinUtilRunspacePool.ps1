function Initialize-WinUtilRunspacePool {
    <#
        .SYNOPSIS
            Opens the shared worker pool that Start-WinUtilJob runs job bodies in
    #>

    $poolLock = Get-WinUtilRunspacePoolLock
    [System.Threading.Monitor]::Enter($poolLock)
    try {
        if ($sync.runspace -and $sync.runspace.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
            return $sync.runspace
        }

        if ($sync.runspace) {
            # A replacement, not a shutdown
            Close-WinUtilRunspacePool -Recycle
        }

        # Set the maximum number of threads for the RunspacePool to the number of threads on the machine.
        $maxthreads = [Math]::Max([int]$env:NUMBER_OF_PROCESSORS, 1)

        $sync.runspace = [runspacefactory]::CreateRunspacePool(
            1,                            # Minimum thread count
            $maxthreads,                  # Maximum thread count
            (New-WinUtilSessionState),    # Initial session state
            $Host                         # Machine to create runspaces on
        )

        $sync.runspace.Open()
        return $sync.runspace
    } finally {
        [System.Threading.Monitor]::Exit($poolLock)
    }
}
