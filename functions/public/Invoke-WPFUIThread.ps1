function Invoke-WPFUIThread {
    <#
        .SYNOPSIS
            Runs a scriptblock on the interface thread

        .DESCRIPTION
            Controls may only be touched from the thread that owns the window, so this is how
            background work reaches them.

            The body is handed to the interface runspace as text and rebuilt there, rather than
            marshalled as a scriptblock from the calling runspace. A scriptblock keeps the
            session state it was written in, and running one across runspaces costs roughly
            twenty times as much per command - enough to turn a checkbox refresh into a visible
            freeze. Values the body needs therefore come in through Parameters instead of being
            captured from the caller's scope.

            The call is a no-op once the window is gone, so a job that outlives the interface
            finishes quietly instead of failing on a dead dispatcher.

        .PARAMETER ScriptBlock
            The work to run on the interface thread. Declare a param block for anything it needs.

        .PARAMETER Parameters
            Values passed to the body by name.

        .PARAMETER Async
            Post the work and return immediately instead of waiting for it. Use for progress and
            log updates, which must never stall the caller.
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock,

        [hashtable]$Parameters = @{},

        [switch]$Async
    )

    $dispatcher = $sync.Form.Dispatcher
    if ($null -eq $dispatcher -or $dispatcher.HasShutdownStarted) {
        return
    }

    if (-not $Async -and $dispatcher.CheckAccess()) {
        return (& $ScriptBlock @Parameters)
    }

    $executor = $sync.UIDispatchDelegate
    if ($null -eq $executor) {
        # No interface runspace to hand the work to; fall back to marshalling the block itself
        if ($Async) {
            $null = $dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, [action]$ScriptBlock)
            return
        }
        return $dispatcher.Invoke([action]$ScriptBlock)
    }

    $work = @{
        Body = $ScriptBlock.ToString()
        Parameters = $Parameters
    }

    if ($Async) {
        $null = $dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, $executor, $work)
        return
    }

    return $dispatcher.Invoke($executor, @($work))
}
