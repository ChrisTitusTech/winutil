function Invoke-WinUtilInstallAppRenderBatch {
    param(
        [Parameter(Mandatory = $true)]
        $CategoryBatch
    )

    # A category is not a unit of work: the largest holds several times as many apps as the
    # smallest, so rendering one per pass hands the interface a stall of unpredictable length.
    $batchLimit = 25
    $remaining = $null
    $keys = $CategoryBatch.AppKeys
    if ($keys.Count -gt $batchLimit) {
        $remaining = $keys[$batchLimit..($keys.Count - 1)]
        $keys = $keys[0..($batchLimit - 1)]
    }

    foreach ($appKey in $keys) {
        $sync.$appKey = Initialize-InstallAppEntry -TargetElement $CategoryBatch.TargetElement -AppKey $appKey
    }

    if ($remaining) {
        $sync.InstallAppRenderQueue.Enqueue([pscustomobject]@{
            Category = $CategoryBatch.Category
            TargetElement = $CategoryBatch.TargetElement
            AppKeys = @($remaining)
        })
    }

    if ($sync.currentTab -eq "Install" -and $sync.SearchBar -and -not [string]::IsNullOrWhiteSpace($sync.SearchBar.Text)) {
        Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Category $sync.SearchBar.Tag
    }
}

function Complete-WinUtilInstallAppRendering {
    $sync.InstallAppEntriesRendered = $true
}

function Invoke-WinUtilInstallAppRenderNextBatch {
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
