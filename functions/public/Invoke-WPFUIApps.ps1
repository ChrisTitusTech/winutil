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
            $mainStackPanel = Initialize-AppStackPanel -TargetGridName $TargetGridName
            $null = Initialize-InstallHeader -TargetElement $mainStackPanel 
            $sync.ItemsControl = Initialize-InstallAppArea -TargetElement $mainStackPanel
            Initialize-InstallCategoryAppList -TargetElement $sync.ItemsControl -Apps $Apps
        }
        default {
            Write-Output "$TargetGridName not yet implemented"
        }
    }
}

