function Invoke-WPFUIApps {
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [PSCustomObject[]]$Apps,
        [Parameter(Mandatory, Position = 1)]
        [string]$TargetGridName
    )

    switch ($TargetGridName) {
        "appspanel" {
            $dockPanel = Initialize-InstallAppsMainElement -TargetGridName $TargetGridName
            log_time_taken "Setup DockPanel for Apps"
            $null = Initialize-InstallHeader -TargetElement $dockPanel
            log_time_taken "Setup Header for Apps"
            $sync.ItemsControl = Initialize-InstallAppArea -TargetElement $dockPanel
            log_time_taken "Setup ItemsControl for Apps"
            Initialize-InstallCategoryAppList -TargetElement $sync.ItemsControl -Apps $Apps
            log_time_taken "UI Initialized"
        }
        default {
            Write-Output "$TargetGridName not yet implemented"
        }
    }
}

