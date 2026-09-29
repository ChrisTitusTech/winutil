function Start-WinUtilTabWarmup {
    <#
        .SYNOPSIS
            Builds the tabs the user has not opened yet, while the interface is idle

        .DESCRIPTION
            Tab content has to be built on the interface thread, so a tab that is still empty
            when it is first clicked makes that click pay for the build. Queueing the builds
            moves that cost to where nothing is waiting on it.

            Queued at background priority rather than idle priority. At idle priority this never
            ran until the app list had finished, which is the exact window in which a tab the
            user clicks is still empty and costs a full build to open.
    #>

    # Win11ISO is left out: building it runs the existing work check, which raises the resume
    # prompt while the user is on another tab. That check belongs to opening the tab, not warming
    # it.
    $pending = [System.Collections.Queue]::new()
    foreach ($tab in @("Tweaks", "Config", "AppX")) {
        if (-not $sync.InitializedTabs[$tab]) {
            $pending.Enqueue($tab)
        }
    }

    if ($pending.Count -eq 0) {
        return
    }

    $sync.TabWarmupQueue = $pending
    Start-WinUtilBackgroundQueue -Name "TabWarmup" -Queue $pending -Step {
        param($Tab)

        Measure-WinUtilStep -Scope "UI" -Name "warm $Tab tab" -ScriptBlock {
            Initialize-WinUtilTabContent -TabName $Tab -Yield
        }
    }
}
