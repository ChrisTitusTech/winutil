function Initialize-WinUtilTabContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TabName
    )

    if ($null -eq $sync.InitializedTabs) {
        $sync.InitializedTabs = @{}
    }

    if ($sync.InitializedTabs[$TabName]) {
        return
    }

    switch ($TabName) {
        "Install" {
            Invoke-WPFUIElements -configVariable $sync.configs.appnavigation -targetGridName "appscategory" -columncount 1
            Initialize-WPFUI -targetGridName "appscategory"
            Write-WinUtilPerformanceCheckpoint -Name "App navigation UI created"

            Initialize-WPFUI -targetGridName "appspanel"
            Write-WinUtilPerformanceCheckpoint -Name "Install UI created"
        }
        "Tweaks" {
            Invoke-WPFUIElements -configVariable $sync.configs.tweaks -targetGridName "tweakspanel" -columncount 2
            Write-WinUtilPerformanceCheckpoint -Name "Tweaks UI created"
        }
        "Config" {
            Invoke-WPFUIElements -configVariable $sync.configs.feature -targetGridName "featurespanel" -columncount 2
            Write-WinUtilPerformanceCheckpoint -Name "Features UI created"
        }
        "AppX" {
            Invoke-WPFUIElements -configVariable $sync.configs.appx -targetGridName "appxpanel" -columncount 2
            Write-WinUtilPerformanceCheckpoint -Name "AppX UI created"
        }
        "Win11 Creator" {
            if ($sync.Form -and $sync.Form.Dispatcher) {
                $sync.Form.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{ Invoke-WinUtilISOCheckExistingWork }) | Out-Null
            }
            Write-WinUtilPerformanceCheckpoint -Name "Win11 ISO tab initialized"
        }
    }

    $sync.InitializedTabs[$TabName] = $true
}
