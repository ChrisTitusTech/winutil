function Start-WinUtilBackgroundQueue {
    <#
        .SYNOPSIS
            Drains a queue of interface work one item at a time, between the things the user does

        .DESCRIPTION
            For work that must run on the interface thread but that nobody waits on: unopened
            tabs, app list entries. One item per queued operation, so input is answered between
            them instead of after the whole list.

            Re-posted rather than looped: only returning to the dispatcher lets it service input.
            Posted as a compiled action rather than through Invoke-WPFUIThread, whose body
            crosses runspaces as text and would recompile on each of the hundreds of posts a full
            app list costs.

        .PARAMETER Name
            Identifies the queue in $sync so a re-posted pump finds its state.

        .PARAMETER Queue
            The queue to drain. Items mean whatever Step says they mean.

        .PARAMETER Step
            Runs one item. Receives the dequeued item.

        .PARAMETER OnComplete
            Runs once on the interface thread after the last item.

        .PARAMETER RequiresTab
            Work drawing into this tab waits while another tab is shown.

        .PARAMETER DeferWhile
            Extra reason to hold off, tested each round. Lets a more urgent queue go first.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        $Queue,

        [Parameter(Mandatory)]
        [scriptblock]$Step,

        [scriptblock]$OnComplete,

        [string]$RequiresTab,

        [scriptblock]$DeferWhile
    )

    if ($null -eq $sync.BackgroundQueues) {
        $sync.BackgroundQueues = [hashtable]::Synchronized(@{})
    }

    $sync.BackgroundQueues[$Name] = @{
        Queue = $Queue
        Step = $Step
        OnComplete = $OnComplete
        RequiresTab = $RequiresTab
        DeferWhile = $DeferWhile
    }

    # No window means no dispatcher to spread over and nothing competing for the thread
    if (-not (Test-WinUtilUIAlive)) {
        while ($Queue.Count -gt 0) {
            # One failing item must not abandon the rest or strand the state, matching the
            # dispatcher path
            try {
                & $Step $Queue.Dequeue()
            } catch {
                Write-WinUtilErrorRecord -ErrorRecord $_ -Component "UI" -Context "Background queue '$Name'"
            }
        }
        if ($OnComplete) { & $OnComplete }
        $sync.BackgroundQueues.Remove($Name)
        return
    }

    Request-WinUtilBackgroundQueueStep -Name $Name
}

function Request-WinUtilBackgroundQueueStep {
    <#
        .SYNOPSIS
            Posts the next step of a queue at background priority

        .PARAMETER Name
            Which queue to advance.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-WinUtilUIAlive)) {
        return
    }

    # The name travels as the dispatcher's argument, not captured: this function has returned by
    # the time the block runs, and a closure would bind command lookup to a copied scope.
    $null = $sync.Form.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Windows.Threading.DispatcherOperationCallback]{
            param($QueueName)
            Invoke-WinUtilBackgroundQueueStep -Name $QueueName
            return $null
        },
        $Name)
}

function Invoke-WinUtilBackgroundQueueStep {
    <#
        .SYNOPSIS
            Runs one item of a queue and asks for the next, or finishes

        .PARAMETER Name
            Which queue to advance.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $state = $sync.BackgroundQueues[$Name]
    if ($null -eq $state) {
        return
    }

    if ($state.Queue.Count -gt 0) {
        $defer = (Test-WinUtilDeferBackgroundWork -RequiresTab $state.RequiresTab) -or
                 ($state.DeferWhile -and (& $state.DeferWhile))

            # Waits rather than competing with whatever the user is doing
        if ($defer) {
            Invoke-WinUtilWhenIdle -Argument $Name -Callback {
                param($QueueName)
                Invoke-WinUtilBackgroundQueueStep -Name $QueueName
            }
            return
        }

        try {
            & $state.Step $state.Queue.Dequeue()
        } catch {
            Write-WinUtilErrorRecord -ErrorRecord $_ -Component "UI" -Context "Background queue '$Name'"
        }
    }

    if ($state.Queue.Count -gt 0) {
        Request-WinUtilBackgroundQueueStep -Name $Name
        return
    }

    $sync.BackgroundQueues.Remove($Name)
    if ($state.OnComplete) { & $state.OnComplete }
}
