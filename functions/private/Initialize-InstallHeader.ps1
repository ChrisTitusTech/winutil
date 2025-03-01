function Initialize-InstallHeader {
    <#
        .SYNOPSIS
            Creates the Multi Selection Header Elements on the Install Tab
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetElement
            The Parent Element into which the Header should be placed
    #>
    param($TargetElement)
    function New-WPFButton {
        param (
            [string]$Name,
            [string]$Content
        )
        $button = New-Object Windows.Controls.Button
        $button.Name = $Name
        $button.Content = $Content
        $button.Margin = New-Object Windows.Thickness(2)
        $button.HorizontalAlignment = "Stretch"
        return $button
    }

    $wrapPanelTop = New-Object Windows.Controls.WrapPanel
    $wrapPanelTop.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "MainBackgroundColor")
    $wrapPanelTop.HorizontalAlignment = "Left"
    $wrapPanelTop.VerticalAlignment = "Top"
    $wrapPanelTop.Orientation = "Horizontal"
    $wrapPanelTop.SetResourceReference([Windows.Controls.Control]::MarginProperty, "TabContentMargin")
    $buttonConfigs = @(
        @{Name="WPFInstall"; Content="Install/Upgrade Selected"},
        @{Name="WPFInstallUpgrade"; Content="Upgrade All"},
        @{Name="WPFUninstall"; Content="Uninstall Selected"}
    )

    foreach ($config in $buttonConfigs) {
        $button = New-WPFButton -Name $config.Name -Content $config.Content
        $null = $wrapPanelTop.Children.Add($button)
        $sync[$config.Name] = $button
    }

    $selectedAppsButton = New-Object Windows.Controls.Button
    $selectedAppsButton.Name = "WPFselectedAppsButton"
    $selectedAppsButton.Content = "Selected Apps: 0"
    $selectedAppsButton.SetResourceReference([Windows.Controls.Control]::FontSizeProperty, "FontSizeHeading")
    $selectedAppsButton.SetResourceReference([Windows.Controls.Control]::MarginProperty, "TabContentMargin")
    $selectedAppsButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $selectedAppsButton.HorizontalAlignment = "Center"
    $selectedAppsButton.VerticalAlignment = "Center"

    $selectedAppsPopup = New-Object Windows.Controls.Primitives.Popup
    $selectedAppsPopup.IsOpen = $false
    $selectedAppsPopup.PlacementTarget = $selectedAppsButton
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
    $selectedAppsButton.Add_Click({
        $sync.selectedAppsPopup.IsOpen = -not $sync.selectedAppsPopup.IsOpen
    })
    # Close selectedAppsPopup when mouse leaves both button and selectedAppsPopup
    $selectedAppsButton.Add_MouseLeave({
        if (-not $sync.selectedAppsPopup.IsMouseOver) {
            $sync.selectedAppsPopup.IsOpen = $false
        }
    })
    $selectedAppsPopup.Add_MouseLeave({
        if (-not $selectedAppsButton.IsMouseOver) {
            $sync.selectedAppsPopup.IsOpen = $false
        }
    })

    $null = $wrapPanelTop.Children.Add($selectedAppsButton)
    $sync.$($selectedAppsButton.Name) = $selectedAppsButton

    [Windows.Controls.DockPanel]::SetDock($wrapPanelTop, [Windows.Controls.Dock]::Top)
    $null = $TargetElement.Children.Add($wrapPanelTop)
}
