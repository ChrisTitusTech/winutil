function Start-WinUtilInstallAppRendering {
    if ($null -eq $sync.InstallAppRenderQueue) {
        return
    }

    $sync.InstallAppEntriesRendered = $false

    $renderCategory = {
        param($CategoryBatch)

        foreach ($appKey in $CategoryBatch.AppKeys) {
            $sync.$appKey = Initialize-InstallAppEntry -TargetElement $CategoryBatch.TargetElement -AppKey $appKey
        }

        if ($sync.currentTab -eq "Install" -and $sync.SearchBar -and -not [string]::IsNullOrWhiteSpace($sync.SearchBar.Text)) {
            Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text
        }
    }

    if ($sync.Form -and $sync.Form.Dispatcher -and ("System.Windows.Threading.DispatcherTimer" -as [type])) {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(1)
        $timer.Add_Tick({
            $timer.Stop()

            if ($sync.InstallAppRenderQueue.Count -gt 0) {
                $categoryBatch = $sync.InstallAppRenderQueue.Dequeue()
                & $renderCategory $categoryBatch
            }

            if ($sync.InstallAppRenderQueue.Count -gt 0) {
                $timer.Start()
                return
            }

            $sync.InstallAppEntriesRendered = $true
            Write-WinUtilPerformanceCheckpoint -Name "Install app entries rendered"
        })
        $sync.InstallAppRenderTimer = $timer
        $timer.Start()
        return
    }

    while ($sync.InstallAppRenderQueue.Count -gt 0) {
        $categoryBatch = $sync.InstallAppRenderQueue.Dequeue()
        & $renderCategory $categoryBatch
    }

    $sync.InstallAppEntriesRendered = $true
    Write-WinUtilPerformanceCheckpoint -Name "Install app entries rendered"
}
