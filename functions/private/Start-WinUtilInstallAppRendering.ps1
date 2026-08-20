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

    # Whatever this batch left without an icon is fetched now rather than at the end of the
    # whole list: waiting meant no icon appeared until every entry had been drawn.

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

    # Once the list is drawn, whatever had no cached icon is fetched on a worker
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
