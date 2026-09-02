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

    # This runs on the dispatcher, so keep the slice free of logging and other disk I/O.
    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    $rendered = 0
    foreach ($appKey in $keys) {
        $sync.$appKey = Initialize-InstallAppEntry -TargetElement $CategoryBatch.TargetElement -AppKey $appKey
        $rendered++
        # at least one per pass, or a slow machine would never finish the list
        if ($clock.ElapsedMilliseconds -ge $budgetMs) {
            break
        }
    }

    if ($rendered -lt $keys.Count) {
        $sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{
            Category = $CategoryBatch.Category
            TargetElement = $CategoryBatch.TargetElement
            AppKeys = @($keys[$rendered..($keys.Count - 1)])
        })
    }

    # Entries render in batches, so a filter that is already active has to be applied to each new
    # batch. Categories count as an active filter just like search text does.
    if ($sync.currentTab -eq "Install" -and $sync.SearchBar) {
        $selectedCategories = if ($sync.SelectedAppCategories) { $sync.SelectedAppCategories.ToArray() } else { @() }

        if (-not [string]::IsNullOrWhiteSpace($sync.SearchBar.Text) -or $selectedCategories.Count -gt 0) {
            Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Categories $selectedCategories
        }
    }
}

function Complete-WinUtilInstallAppRendering {
    $sync.InstallAppEntriesRendered = $true

}

function Start-WinUtilInstallAppRendering {
    if ($null -eq $sync.InstallAppRenderQueue) {
        return
    }

    $sync.InstallAppEntriesRendered = $false

    Start-WinUtilBackgroundQueue -Name "InstallAppRender" -Queue $sync.InstallAppRenderQueue `
        -RequiresTab "Install" `
        -Step { param($CategoryBatch) Invoke-WinUtilInstallAppRenderBatch -CategoryBatch $CategoryBatch } `
        -OnComplete { Complete-WinUtilInstallAppRendering } `
        -DeferWhile {
            # Tabs that have never been built come first. This list is already on screen and
            # filling in, while another tab is empty until it is built, so a click on one costs
            # the whole build. The list finishing a little later is not felt; a tab that takes
            # half a second to open is.
            $sync.TabWarmupQueue -and $sync.TabWarmupQueue.Count -gt 0
        }
}
