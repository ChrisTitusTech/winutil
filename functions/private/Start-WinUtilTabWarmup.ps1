function Start-WinUtilTabWarmup {
    <#
        .SYNOPSIS
            Builds the tabs the user has not opened yet, while the interface is idle

        .DESCRIPTION
            Tab content has to be built on the interface thread, so a tab that is still empty
            when it is first clicked makes that click pay for the build. Queueing the builds at
            idle priority moves that cost to where nothing is waiting on it.

            One tab per queued operation, so the interface can service input between them
            rather than being held for the length of every remaining tab.
    #>

    $dispatcher = $sync.Form.Dispatcher
    if ($null -eq $dispatcher -or $dispatcher.HasShutdownStarted) {
        return
    }

    $pending = [System.Collections.Queue]::new()
    foreach ($tab in @("Tweaks", "Config", "AppX", "Win11ISO")) {
        if (-not $sync.InitializedTabs[$tab]) {
            $pending.Enqueue($tab)
        }
    }

    if ($pending.Count -eq 0) {
        return
    }

    $sync.TabWarmupQueue = $pending
    $null = $dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::ApplicationIdle, [action]{
        Invoke-WinUtilTabWarmupStep
    })
}

function Invoke-WinUtilTabWarmupStep {
    <#
        .SYNOPSIS
            Builds the next queued tab and re-queues itself while any remain
    #>

    if ($null -eq $sync.TabWarmupQueue -or $sync.TabWarmupQueue.Count -eq 0) {
        return
    }

    $tab = $sync.TabWarmupQueue.Dequeue()
    try {
        Measure-WinUtilStep -Scope "UI" -Name "warm $tab tab" -ScriptBlock {
            Initialize-WinUtilTabContent -TabName $tab
        }
    } catch {
        Write-WinUtilErrorRecord -ErrorRecord $_ -Component "UI" -Context "Warming the $tab tab"
    }

    if ($sync.TabWarmupQueue.Count -gt 0 -and $sync.Form.Dispatcher -and -not $sync.Form.Dispatcher.HasShutdownStarted) {
        $null = $sync.Form.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::ApplicationIdle, [action]{
            Invoke-WinUtilTabWarmupStep
        })
    }
}
