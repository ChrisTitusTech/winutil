function Register-WinUtilInputWatch {
    <#
        .SYNOPSIS
            Records when the user last did something, so background work can step aside

        .DESCRIPTION
            Preview events run before the control handles the input, so the timestamp is set
            even for a click the control then spends time on.
    #>

    $sync.LastInputAt = [datetime]::MinValue

    $stamp = { $sync.LastInputAt = [datetime]::Now }
    $sync.Form.Add_PreviewMouseDown($stamp)
    $sync.Form.Add_PreviewKeyDown($stamp)
    $sync.Form.Add_PreviewMouseWheel($stamp)
}

function Test-WinUtilDeferBackgroundWork {
    <#
        .SYNOPSIS
            Whether speculative work should wait rather than run now

        .DESCRIPTION
            Background priority queues work behind input but does not make it interruptible:
            whatever is running must finish before a click is looked at, which is why the pieces
            are kept short. Waits while the user is active, or while the work draws into a tab
            that is not on screen.

        .PARAMETER RequiresTab
            The tab this work draws into. Work for a hidden tab waits.
    #>
    param(
        [string]$RequiresTab
    )

    if ($sync.LastInputAt) {
        $sinceInput = ([datetime]::Now - $sync.LastInputAt).TotalMilliseconds
        # long enough to cover a click and the work it starts, short enough not to be noticed
        if ($sinceInput -lt 400) {
            return $true
        }
    }

    if ($RequiresTab -and $sync.currentTab -and $sync.currentTab -ne $RequiresTab) {
        return $true
    }

    return $false
}

function Invoke-WinUtilWhenIdle {
    <#
        .SYNOPSIS
            Runs a callback once the interface is not being used

        .DESCRIPTION
            A one shot timer, not a dispatcher post: a post at background priority runs straight
            away and the point is to leave a gap.

        .PARAMETER Callback
            What to run once the wait is over.

        .PARAMETER Argument
            Passed to the callback. Carried on the timer rather than captured, so the callback
            resolves commands where it was written, not in a copied scope.

        .PARAMETER DelayMilliseconds
            How long to wait before looking again.
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Callback,

        $Argument,

        [int]$DelayMilliseconds = 150
    )

    if (-not (Test-WinUtilUIAlive)) {
        return
    }

    # Bound to the interface dispatcher explicitly: the default picks up the calling thread's,
    # which is only correct while every caller reaches here through a UI post
    $timer = New-Object System.Windows.Threading.DispatcherTimer([System.Windows.Threading.DispatcherPriority]::Background, $sync.Form.Dispatcher)
    $timer.Interval = [timespan]::FromMilliseconds($DelayMilliseconds)
    $timer.Tag = @{ Callback = $Callback; Argument = $Argument }
    # Sender taken from the argument, matching how the rest of this codebase handles timer ticks
    $timer.Add_Tick({
        param($eventSender)
        $ticked = [System.Windows.Threading.DispatcherTimer]$eventSender
        $ticked.Stop()
        & $ticked.Tag.Callback $ticked.Tag.Argument
    })
    $timer.Start()
}
