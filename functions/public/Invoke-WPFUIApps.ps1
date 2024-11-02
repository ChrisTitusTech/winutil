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
            $null = Initialize-InstallHeader -TargetElement $dockPanel
            $sync.ItemsControl = Initialize-InstallAppArea -TargetElement $dockPanel
            Initialize-InstallCategoryAppList -TargetElement $sync.ItemsControl -Apps $Apps
        }
        default {
            Write-Output "$TargetGridName not yet implemented"
        }
    }
}

