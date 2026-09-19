function Get-WinUtilRunspacePoolLock {
    <#
        .SYNOPSIS
            Returns the lock that serializes worker-pool startup and shutdown
    #>

    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if ($null -eq $sync.RunspacePoolLock) {
            $sync.RunspacePoolLock = [object]::new()
        }

        return $sync.RunspacePoolLock
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }
}
