function Invoke-WinUtilInstallAppRenderBatch {
    param(
        [Parameter(Mandatory = $true)]
        $CategoryBatch
    )

    # A count is not a unit of time. How long a fixed number of entries takes depends on the
    # machine and on the category, so the pass runs to a deadline instead and hands back
    # whatever it did not reach. That caps how long a click can be left waiting.
    $budgetMs = 25
    $keys = @($CategoryBatch.AppKeys)

    # The count is the step's return value rather than a variable the loop updates: a scriptblock
    # runs in a child scope, so assigning to an outer variable from inside it silently writes to
    # a copy, and the pass would re-queue everything it had just drawn.
    $rendered = Measure-WinUtilStep -Scope "AppRender" -Name $CategoryBatch.Category -ScriptBlock {
        $clock = [System.Diagnostics.Stopwatch]::StartNew()
        $done = 0
        foreach ($appKey in $keys) {
            $sync.$appKey = Initialize-InstallAppEntry -TargetElement $CategoryBatch.TargetElement -AppKey $appKey
            $done++
            # at least one per pass, or a slow machine would never finish the list
            if ($clock.ElapsedMilliseconds -ge $budgetMs) {
                break
            }
        }
        $done
    }

    if ($rendered -lt $keys.Count) {
        $sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{
            Category = $CategoryBatch.Category
            TargetElement = $CategoryBatch.TargetElement
            AppKeys = @($keys[$rendered..($keys.Count - 1)])
        })
    }

    if ($sync.currentTab -eq "Install" -and $sync.SearchBar -and -not [string]::IsNullOrWhiteSpace($sync.SearchBar.Text)) {
        Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Category $sync.SearchBar.Tag
    }
}

function Complete-WinUtilInstallAppRendering {
    $sync.InstallAppEntriesRendered = $true

    # Once the list is drawn, whatever had no cached icon is fetched on a worker
    Start-WinUtilIconFetch
}

function Invoke-WinUtilInstallAppRenderNextBatch {
    # Nothing here is worth a moment of the user's time: the entries are either not on screen or
    # being drawn while they are trying to do something else.
    #
    # Tabs that have never been built come first. This list is already on screen and filling in,
    # while another tab is empty until it is built, so a click on one costs the whole build. The
    # list finishing a little later is not felt; a tab that takes half a second to open is.
    $tabsPending = $sync.TabWarmupQueue -and $sync.TabWarmupQueue.Count -gt 0
    if ($sync.InstallAppRenderQueue.Count -gt 0 -and ($tabsPending -or (Test-WinUtilDeferBackgroundWork -RequiresTab "Install"))) {
        Invoke-WinUtilWhenIdle -Callback { Invoke-WinUtilInstallAppRenderNextBatch }
        return
    }

    if ($sync.InstallAppRenderQueue.Count -gt 0) {
        $categoryBatch = $sync.InstallAppRenderQueue.Dequeue()
        Invoke-WinUtilInstallAppRenderBatch -CategoryBatch $categoryBatch
    }

    if ($sync.InstallAppRenderQueue.Count -gt 0) {
        $sync.Form.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{ Invoke-WinUtilInstallAppRenderNextBatch }
        ) | Out-Null
        return
    }

    Complete-WinUtilInstallAppRendering
}

function Start-WinUtilInstallAppRendering {
    if ($null -eq $sync.InstallAppRenderQueue) {
        return
    }

    $sync.InstallAppEntriesRendered = $false
    if ($null -eq $sync.IconImages) { $sync.IconImages = [hashtable]::Synchronized(@{}) }
    if ($null -eq $sync.PendingIcons) { $sync.PendingIcons = [hashtable]::Synchronized(@{}) }

    if ($sync.Form -and $sync.Form.Dispatcher) {
        $sync.Form.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{ Invoke-WinUtilInstallAppRenderNextBatch }
        ) | Out-Null
        return
    }

    while ($sync.InstallAppRenderQueue.Count -gt 0) {
        $categoryBatch = $sync.InstallAppRenderQueue.Dequeue()
        Invoke-WinUtilInstallAppRenderBatch -CategoryBatch $categoryBatch
    }

    Complete-WinUtilInstallAppRendering
}
