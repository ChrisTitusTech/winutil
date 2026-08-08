function Register-WinUtilInputWatch {
    <#
        .SYNOPSIS
            Records when the user last did something, so background work can step aside

        .DESCRIPTION
            Preview events are used because they run before the control handles the input, so
            the timestamp is set even for a click that a control goes on to spend time on.
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
            Background priority puts work behind input in the queue, but it does not make a piece
            of work interruptible: whatever is running has to finish before a click is looked at.
            A steady stream of short pieces therefore never shows up as one long stall while
            still leaving everything the user does waiting behind the piece in flight.

            Two reasons to wait. The user is doing something, in which case the thread is better
            spent on them; or what is being built is not on screen, in which case it is not worth
            competing with what is.

        .PARAMETER RequiresTab
            The tab this work draws into. Work for a tab the user is not looking at waits.
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
            A one shot timer rather than a dispatcher post, because a post at background priority
            would run straight away and the point is to leave a gap.

        .PARAMETER Callback
            What to run once the wait is over.

        .PARAMETER DelayMilliseconds
            How long to wait before looking again.
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Callback,

        [int]$DelayMilliseconds = 150
    )

    if ($null -eq $sync.Form -or $null -eq $sync.Form.Dispatcher -or $sync.Form.Dispatcher.HasShutdownStarted) {
        return
    }

    $timer = New-Object System.Windows.Threading.DispatcherTimer([System.Windows.Threading.DispatcherPriority]::Background)
    $timer.Interval = [timespan]::FromMilliseconds($DelayMilliseconds)
    $timer.Tag = $Callback
    # Sender taken from the argument, matching how the rest of this codebase handles timer ticks
    $timer.Add_Tick({
        param($eventSender)
        $ticked = [System.Windows.Threading.DispatcherTimer]$eventSender
        $ticked.Stop()
        & $ticked.Tag
    })
    $timer.Start()
}
