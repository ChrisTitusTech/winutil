function Invoke-WinUtilInstallAppRenderBatch {
    param(
        [Parameter(Mandatory = $true)]
        $CategoryBatch
    )

    foreach ($appKey in $CategoryBatch.AppKeys) {
        $sync.$appKey = Initialize-InstallAppEntry -TargetElement $CategoryBatch.TargetElement -AppKey $appKey
    }

    if ($sync.currentTab -eq "Install" -and $sync.SearchBar -and -not [string]::IsNullOrWhiteSpace($sync.SearchBar.Text)) {
        Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text
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
