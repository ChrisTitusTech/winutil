function Invoke-WinUtilInstallAppRenderBatch {
    param(
        [Parameter(Mandatory = $true)]
        $CategoryBatch,

        # How many entries to build in this pass. Entries are built in one parse each, so a pass
        # costs a few milliseconds per ten entries; the rest goes back on the queue.
        [int]$ChunkSize = 40
    )

    $keys = @($CategoryBatch.AppKeys)
    $count = [Math]::Min($keys.Count, $ChunkSize)
    $chunk = @($keys[0..($count - 1)])

    # This runs on the dispatcher, so keep the slice free of logging and other disk I/O.
    $checkBoxes = @(Initialize-InstallAppEntries -TargetElement $CategoryBatch.TargetElement -AppKeys $chunk)
    for ($i = 0; $i -lt $chunk.Count; $i++) {
        $sync.($chunk[$i]) = $checkBoxes[$i]
    }

    if ($count -lt $keys.Count) {
        $sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{
            Category = $CategoryBatch.Category
            TargetElement = $CategoryBatch.TargetElement
            AppKeys = @($keys[$count..($keys.Count - 1)])
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

    # Before the window is shown nothing is waiting on the interface thread, so the whole list is
    # built in one pass and the window opens complete instead of filling in
    if ($sync.BuildingBeforeShow) {
        while ($sync.InstallAppRenderQueue.Count -gt 0) {
            Invoke-WinUtilInstallAppRenderBatch -CategoryBatch $sync.InstallAppRenderQueue.Dequeue() -ChunkSize ([int]::MaxValue)
        }
        Complete-WinUtilInstallAppRendering
        return
    }

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
