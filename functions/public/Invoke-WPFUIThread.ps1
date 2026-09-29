function Test-WinUtilUIAlive {
    <#
        .SYNOPSIS
            Whether there is a window that can still be posted to

        .DESCRIPTION
            False for a headless run, and for a window closed over running work: a shut down
            dispatcher accepts posts and discards them.
    #>

    return $null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher -and -not $sync.Form.Dispatcher.HasShutdownStarted
}

function Test-WinUtilDispatcherShutdownException {
    param([System.Exception]$Exception)

    while ($null -ne $Exception) {
        if ($Exception -is [System.OperationCanceledException] -or
            $Exception -is [System.InvalidOperationException]) {
            return $true
        }
        $Exception = $Exception.InnerException
    }

    return $false
}

function Invoke-WPFUIThread {
    <#
        .SYNOPSIS
            Runs a scriptblock on the interface thread

        .DESCRIPTION
            Controls may only be touched from the thread that owns the window.

            The body is handed over as text and rebuilt in the interface runspace rather than
            marshalled as a scriptblock: a scriptblock keeps the session state it was written in,
            and running one across runspaces costs roughly twenty times as much per command. So
            values come in through Parameters rather than captured from the caller's scope.

            A no-op once the window is gone, so a job outliving the interface finishes quietly.

        .PARAMETER ScriptBlock
            The work to run on the interface thread. Declare a param block for anything it needs.

        .PARAMETER Parameters
            Values passed to the body by name.

        .PARAMETER Async
            Post and return instead of waiting. For progress and log updates, which must never
            stall the caller.

        .PARAMETER PassThru
            Return what the body produced. Off by default so a caller that only wanted a control
            updated gets no stray output.
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock,

        [hashtable]$Parameters = @{},

        [switch]$Async,

        [switch]$PassThru
    )

    if (-not (Test-WinUtilUIAlive)) {
        return
    }
    $dispatcher = $sync.Form.Dispatcher

    if (-not $Async -and $dispatcher.CheckAccess()) {
        $inlineResult = & $ScriptBlock @Parameters
        if ($PassThru) { return $inlineResult }
        return
    }

    $executor = $sync.UIDispatchDelegate
    if ($null -eq $executor) {
        # No interface runspace to hand the work to, so the block itself is marshalled. It has to
        # receive its parameters and return what it produced, and [action] carries neither.
        if ($Async) {
            # The values travel as the dispatcher's argument, since this call returns before the
            # block runs and anything captured from here would be gone by then
            try {
                $null = $dispatcher.BeginInvoke(
                    [Windows.Threading.DispatcherPriority]::Background,
                    [System.Windows.Threading.DispatcherOperationCallback]{
                        param($Work)
                        $body = $Work.Body
                        $arguments = $Work.Parameters
                        if ($arguments -and $arguments.Count -gt 0) {
                            $null = & $body @arguments
                        } else {
                            $null = & $body
                        }
                        return $null
                    },
                    @{ Body = $ScriptBlock; Parameters = $Parameters })
            } catch {
                $shutdownFailure = Test-WinUtilDispatcherShutdownException -Exception $_.Exception
                if ($shutdownFailure -and -not (Test-WinUtilUIAlive)) { return }
                throw
            }
            return
        }

        # Synchronous, so this frame is still alive while the block runs and can be captured from
        try {
            $fallbackResult = $dispatcher.Invoke([System.Func[object]]{ & $ScriptBlock @Parameters })
        } catch {
            $shutdownFailure = Test-WinUtilDispatcherShutdownException -Exception $_.Exception
            if ($shutdownFailure -and -not (Test-WinUtilUIAlive)) { return }
            throw
        }
        if ($PassThru) { return $fallbackResult }
        return
    }

    $work = @{
        Body = $ScriptBlock.ToString()
        Parameters = $Parameters
        # A synchronous caller is waiting for a required UI handoff and must see its failure.
        # Fire-and-forget posts have nobody to receive an exception, so the delegate only logs it.
        PropagateErrors = -not $Async
    }

    if ($Async) {
        try {
            $null = $dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, $executor, $work)
        } catch {
            $shutdownFailure = Test-WinUtilDispatcherShutdownException -Exception $_.Exception
            if ($shutdownFailure -and -not (Test-WinUtilUIAlive)) { return }
            throw
        }
        return
    }

    try {
        $result = $dispatcher.Invoke($executor, @($work))
    } catch {
        $shutdownFailure = Test-WinUtilDispatcherShutdownException -Exception $_.Exception
        if ($shutdownFailure -and -not (Test-WinUtilUIAlive)) { return }
        throw
    }
    if ($PassThru) { return $result }
}
