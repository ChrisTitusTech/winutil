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
            # $null = Initialize-InstallHeader -TargetElement $dockPanel

            $selectedAppsPopup = New-Object Windows.Controls.Primitives.Popup
            $selectedAppsPopup.IsOpen = $false
            $selectedAppsPopup.PlacementTarget = $sync.WPFselectedAppsButton
            $selectedAppsPopup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
            $selectedAppsPopup.AllowsTransparency = $true

            $selectedAppsBorder = New-Object Windows.Controls.Border
            $selectedAppsBorder.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "MainBackgroundColor")
            $selectedAppsBorder.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "MainForegroundColor")
            $selectedAppsBorder.SetResourceReference([Windows.Controls.Control]::BorderThicknessProperty, "ButtonBorderThickness")
            $selectedAppsBorder.Width = 200
            $selectedAppsBorder.Padding = 5
            $selectedAppsPopup.Child = $selectedAppsBorder
            $sync.selectedAppsPopup = $selectedAppsPopup

            $sync.selectedAppsstackPanel = New-Object Windows.Controls.StackPanel
            $selectedAppsBorder.Child = $sync.selectedAppsstackPanel

            # Toggle selectedAppsPopup open/close with button
            $sync.WPFselectedAppsButton.Add_Click({
                $sync.selectedAppsPopup.IsOpen = -not $sync.selectedAppsPopup.IsOpen
            })
            # Close selectedAppsPopup when mouse leaves both button and selectedAppsPopup
            $sync.WPFselectedAppsButton.Add_MouseLeave({
                if (-not $sync.selectedAppsPopup.IsMouseOver) {
                    $sync.selectedAppsPopup.IsOpen = $false
                }
            })
            $selectedAppsPopup.Add_MouseLeave({
                if (-not $sync.WPFselectedAppsButton.IsMouseOver) {
                    $sync.selectedAppsPopup.IsOpen = $false
                }
            })
            $sync.ItemsControl = Initialize-InstallAppArea -TargetElement $dockPanel
            Initialize-InstallCategoryAppList -TargetElement $sync.ItemsControl -Apps $Apps
        }
        default {
            Write-Output "$TargetGridName not yet implemented"
        }
    }
}

