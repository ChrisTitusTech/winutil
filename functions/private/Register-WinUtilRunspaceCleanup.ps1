function Register-WinUtilRunspaceCleanup {
    <#
        .SYNOPSIS
            Disposes a PowerShell instance once its work has finished

        .DESCRIPTION
            Ends the invocation and disposes the instance from a thread pool callback, so
            nothing has to wait for a fire-and-forget runspace to complete just to clean it up.

        .PARAMETER PowerShell
            The instance to dispose.

        .PARAMETER Handle
            The handle returned by its BeginInvoke.

        .PARAMETER Runspace
            A runspace created for this instance alone, disposed with it. Instances running on
            the shared pool must not pass this: the pool owns their runspaces.
    #>
    param(
        [Parameter(Mandatory)]
        $PowerShell,

        [Parameter(Mandatory)]
        $Handle,

        $Runspace
    )

    if (-not ("WinUtilRunspaceCleanup" -as [type])) {
        Add-Type @"
using System;
using System.Management.Automation;

public sealed class WinUtilRunspaceCleanupState
{
    public PowerShell PowerShell { get; set; }
    public IAsyncResult Handle { get; set; }
    public IDisposable Runspace { get; set; }
}

public static class WinUtilRunspaceCleanup
{
    public static readonly System.Threading.WaitOrTimerCallback Callback = Cleanup;

    public static void Cleanup(object state, bool timedOut)
    {
        var cleanupState = state as WinUtilRunspaceCleanupState;
        if (cleanupState == null || cleanupState.PowerShell == null || cleanupState.Handle == null)
        {
            return;
        }

        try
        {
            cleanupState.PowerShell.EndInvoke(cleanupState.Handle);
        }
        catch
        {
        }
        finally
        {
            cleanupState.PowerShell.Dispose();

            if (cleanupState.Runspace != null)
            {
                try
                {
                    cleanupState.Runspace.Dispose();
                }
                catch
                {
                }
            }
        }
    }
}
"@
    }

    $cleanupState = [WinUtilRunspaceCleanupState]::new()
    $cleanupState.PowerShell = $PowerShell
    $cleanupState.Handle = $Handle
    $cleanupState.Runspace = $Runspace
    [System.Threading.ThreadPool]::RegisterWaitForSingleObject($Handle.AsyncWaitHandle, [WinUtilRunspaceCleanup]::Callback, $cleanupState, -1, $true) | Out-Null
}
