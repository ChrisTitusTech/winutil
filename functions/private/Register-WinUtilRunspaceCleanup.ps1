function Register-WinUtilRunspaceCleanup {
    <#
        .SYNOPSIS
            Disposes a PowerShell instance and any owned runspace once its work has finished

        .DESCRIPTION
            Ends the invocation and disposes the instance from a thread pool callback, so
            nothing has to wait for a fire-and-forget runspace to complete just to clean it up.

        .PARAMETER PowerShell
            The instance to dispose.

        .PARAMETER Handle
            The handle returned by its BeginInvoke.

        .PARAMETER Runspace
            A dedicated runspace owned by the invocation. Shared pool invocations omit it.
    #>
    param(
        [Parameter(Mandatory)]
        $PowerShell,

        [Parameter(Mandatory)]
        $Handle,

        $Runspace
    )

    # Version the CLR helper because Add-Type definitions survive repeated in-memory WinUtil runs.
    # Older sessions can already contain the V1 type, whose state object has no Runspace property.
    if (-not ("WinUtilRunspaceCleanupV3" -as [type])) {
        Add-Type @"
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;

public sealed class WinUtilRunspaceCleanupStateV3
{
    public PowerShell PowerShell { get; set; }
    public IAsyncResult Handle { get; set; }
    public Runspace Runspace { get; set; }
}

public static class WinUtilRunspaceCleanupV3
{
    public static readonly System.Threading.WaitOrTimerCallback Callback = Cleanup;

    public static bool Register(WinUtilRunspaceCleanupStateV3 state)
    {
        try
        {
            ThreadPool.RegisterWaitForSingleObject(state.Handle.AsyncWaitHandle, Callback, state, -1, true);
            return true;
        }
        catch
        {
            // Registration is normally infallible, but work has already started. A background
            // waiter preserves asynchronous cleanup without blocking the WPF dispatcher.
            try
            {
                var thread = new Thread(() =>
                {
                    try
                    {
                        state.Handle.AsyncWaitHandle.WaitOne();
                    }
                    catch
                    {
                    }
                    Cleanup(state, false);
                });
                thread.IsBackground = true;
                thread.Name = "WinUtil runspace cleanup fallback";
                thread.Start();
                return true;
            }
            catch
            {
                return false;
            }
        }
    }

    public static void Cleanup(object state, bool timedOut)
    {
        var cleanupState = state as WinUtilRunspaceCleanupStateV3;
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
                    cleanupState.Runspace.Close();
                }
                catch
                {
                }
                finally
                {
                    cleanupState.Runspace.Dispose();
                }
            }
        }
    }
}
"@
    }

    $cleanupState = [WinUtilRunspaceCleanupStateV3]::new()
    $cleanupState.PowerShell = $PowerShell
    $cleanupState.Handle = $Handle
    $cleanupState.Runspace = $Runspace
    $registered = [WinUtilRunspaceCleanupV3]::Register($cleanupState)
    if (-not $registered) {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not register asynchronous cleanup for background work; it will be reclaimed when later work or shutdown inspects it."
    }
}
