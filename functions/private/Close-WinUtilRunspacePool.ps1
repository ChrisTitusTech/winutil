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

    if ($null -eq $sync) {
        return
    }

    $poolLock = Get-WinUtilRunspacePoolLock
    [System.Threading.Monitor]::Enter($poolLock)
    try {
        # Set before stopping, so nothing that is winding down queues fresh work behind us
        if (-not $Recycle) {
            $sync.ShuttingDown = $true
        }

        if (-not $sync.ContainsKey("runspace") -or $null -eq $sync.runspace) {
            return
        }

        $stopped = $true
        try {
            $stopped = Stop-WinUtilActiveWork -TimeoutSeconds $StopTimeoutSeconds
        } catch {
            $stopped = $false
            Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not stop running work cleanly: $($_.Exception.Message)"
        }

        $pool = $sync.runspace
        $cleanupDeferred = $false
        try {
            $poolState = $pool.RunspacePoolStateInfo.State
            $terminalStates = @(
                [System.Management.Automation.Runspaces.RunspacePoolState]::Closed,
                [System.Management.Automation.Runspaces.RunspacePoolState]::Broken
            )

            if (-not $stopped -and $poolState -notin $terminalStates) {
                # Close and Dispose both wait for an invocation that ignored BeginStop. Hand
                # cleanup to the thread pool so the timeout above remains a real upper bound.
                $cleanupDeferred = $true
                if ($poolState -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Closing) {
                    Register-WinUtilRunspacePoolCleanup -RunspacePool $pool
                }
            } elseif ($poolState -notin ($terminalStates + [System.Management.Automation.Runspaces.RunspacePoolState]::Closing)) {
                $pool.Close()
            }
        } catch {
            # A pool that will not close cleanly must not stop the window from closing
            Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Worker pool did not close cleanly: $($_.Exception.Message)"
        } finally {
            if (-not $cleanupDeferred) {
                try {
                    $pool.Dispose()
                } catch {
                    Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Worker pool did not dispose cleanly: $($_.Exception.Message)"
                }
            }
            $sync.Remove("runspace")
            if ($sync.ActiveShells) { $sync.ActiveShells.Clear() }
        }
    } finally {
        [System.Threading.Monitor]::Exit($poolLock)
    }
}

function Register-WinUtilRunspacePoolCleanup {
    <#
        .SYNOPSIS
            Closes and disposes a worker pool without blocking the calling thread
    #>
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool
    )

    if (-not ("WinUtilRunspacePoolCleanup" -as [type])) {
        Add-Type @"
using System;
using System.Management.Automation.Runspaces;

public sealed class WinUtilRunspacePoolCleanupState
{
    public RunspacePool RunspacePool { get; set; }
    public IAsyncResult Handle { get; set; }
}

public static class WinUtilRunspacePoolCleanup
{
    public static readonly System.Threading.WaitOrTimerCallback Callback = Cleanup;

    public static void Cleanup(object state, bool timedOut)
    {
        var cleanupState = state as WinUtilRunspacePoolCleanupState;
        if (cleanupState == null || cleanupState.RunspacePool == null || cleanupState.Handle == null)
        {
            return;
        }

        try
        {
            cleanupState.RunspacePool.EndClose(cleanupState.Handle);
        }
        catch
        {
        }
        finally
        {
            try
            {
                cleanupState.RunspacePool.Dispose();
            }
            catch
            {
            }
        }
    }
}
"@
    }

    $cleanupState = [WinUtilRunspacePoolCleanupState]::new()
    $cleanupState.RunspacePool = $RunspacePool
    $cleanupState.Handle = $RunspacePool.BeginClose($null, $null)
    [System.Threading.ThreadPool]::RegisterWaitForSingleObject(
        $cleanupState.Handle.AsyncWaitHandle,
        [WinUtilRunspacePoolCleanup]::Callback,
        $cleanupState,
        -1,
        $true
    ) | Out-Null
}
