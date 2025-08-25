function Initialize-WPFUI {
    <#
        .SYNOPSIS
            Enhanced version of Initialize-WPFUI with responsive design and modern styling.
            Provides improved layout and performance for application panels.
        .PARAMETER TargetGridName
            The name of the target grid to initialize
        .PARAMETER UseResponsiveLayout
            Enable responsive layout features (default: true)
        .PARAMETER ItemWidth
            Item width for responsive layout (0 = auto-calculate)
    #>
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$TargetGridName,

        [Parameter()]
        [bool]$UseResponsiveLayout = $true,

        [Parameter()]
        [double]$ItemWidth = 0
    )

    switch ($TargetGridName) {
        "appscategory" {
            # Keep original functionality for app category sidebar
            # Create and configure a popup for displaying selected apps
            $selectedAppsPopup = New-Object Windows.Controls.Primitives.Popup
            $selectedAppsPopup.IsOpen = $false
            $selectedAppsPopup.PlacementTarget = $sync.WPFselectedAppsButton
            $selectedAppsPopup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
            $selectedAppsPopup.AllowsTransparency = $true

            # Style the popup with a border and background
            $selectedAppsBorder = New-Object Windows.Controls.Border
            $selectedAppsBorder.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "MainBackgroundColor")
            $selectedAppsBorder.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "MainForegroundColor")
            $selectedAppsBorder.SetResourceReference([Windows.Controls.Control]::BorderThicknessProperty, "ButtonBorderThickness")
            $selectedAppsBorder.Width = 200
            $selectedAppsBorder.Padding = 5
            $selectedAppsPopup.Child = $selectedAppsBorder
            $sync.selectedAppsPopup = $selectedAppsPopup

            # Add a stack panel inside the popup's border to organize its child elements
            $sync.selectedAppsstackPanel = New-Object Windows.Controls.StackPanel
            $selectedAppsBorder.Child = $sync.selectedAppsstackPanel

            # Enhanced mouse interaction for better UX
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

            # Enhanced app popup with modern styling
            $appPopup = New-Object Windows.Controls.Primitives.Popup
            $appPopup.StaysOpen = $false
            $appPopup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
            $appPopup.AllowsTransparency = $true
            $sync.appPopup = $appPopup

            $appPopupBorder = New-Object Windows.Controls.Border
            $appPopupBorder.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "MainBackgroundColor")
            $appPopupBorder.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
            $appPopupBorder.BorderThickness = '1'
            $appPopupBorder.CornerRadius = '6'
            $appPopupBorder.Padding = '4'
            $appPopup.Child = $appPopupBorder

            $appPopupStackPanel = New-Object Windows.Controls.StackPanel
            $appPopupStackPanel.Orientation = "Horizontal"
            $appPopupStackPanel.Add_MouseLeave({
                $sync.appPopup.IsOpen = $false
            })
            $appPopupBorder.Child = $appPopupStackPanel

            # Enhanced app action buttons
            $appButtons = @(
                [PSCustomObject]@{ Name = "Install";    Icon = [char]0xE118; Color = "MainForegroundColor" },
                [PSCustomObject]@{ Name = "Uninstall";  Icon = [char]0xE74D; Color = "MainForegroundColor" },
                [PSCustomObject]@{ Name = "Info";       Icon = [char]0xE946; Color = "MainForegroundColor" }
            )

            foreach ($button in $appButtons) {
                $newButton = New-Object Windows.Controls.Button
                $newButton.Style = $sync.Form.Resources.AppEntryButtonStyle
                $newButton.Content = $button.Icon
                $newButton.Width = 32
                $newButton.Height = 32
                $newButton.Margin = '2'
                $newButton.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, $button.Color)
                $appPopupStackPanel.Children.Add($newButton) | Out-Null

                # Enhanced button interactions
                switch ($button.Name) {
                    "Install" {
                        $newButton.Add_MouseEnter({
                            $appObject = $sync.configs.applicationsHashtable.$($sync.appPopupSelectedApp)
                            $this.ToolTip = "Install or Upgrade $($appObject.content)"
                            $this.Opacity = 0.8
                        })
                        $newButton.Add_MouseLeave({ $this.Opacity = 1.0 })
                        $newButton.Add_Click({
                            $appObject = $sync.configs.applicationsHashtable.$($sync.appPopupSelectedApp)
                            Invoke-WPFInstall -PackagesToInstall $appObject
                        })
                    }
                    "Uninstall" {
                        $newButton.Add_MouseEnter({
                            $appObject = $sync.configs.applicationsHashtable.$($sync.appPopupSelectedApp)
                            $this.ToolTip = "Uninstall $($appObject.content)"
                            $this.Opacity = 0.8
                        })
                        $newButton.Add_MouseLeave({ $this.Opacity = 1.0 })
                        $newButton.Add_Click({
                            $appObject = $sync.configs.applicationsHashtable.$($sync.appPopupSelectedApp)
                            Invoke-WPFUnInstall -PackagesToUninstall $appObject
                        })
                    }
                    "Info" {
                        $newButton.Add_MouseEnter({
                            $appObject = $sync.configs.applicationsHashtable.$($sync.appPopupSelectedApp)
                            $this.ToolTip = "Open the application's website`n$($appObject.link)"
                            $this.Opacity = 0.8
                        })
                        $newButton.Add_MouseLeave({ $this.Opacity = 1.0 })
                        $newButton.Add_Click({
                            $appObject = $sync.configs.applicationsHashtable.$($sync.appPopupSelectedApp)
                            if ($appObject.link -and $appObject.link -ne "na") {
                                Start-Process $appObject.link
                            }
                        })
                    }
                }
            }
        }

        "appspanel" {
            # Enhanced applications panel with responsive design
            $sync.ItemsControl = Initialize-InstallAppArea -TargetElement $TargetGridName -UseResponsiveLayout $UseResponsiveLayout
            Initialize-InstallCategoryAppList -TargetElement $sync.ItemsControl -Apps $sync.configs.applicationsHashtable -ItemWidth $ItemWidth -UseResponsiveLayout $UseResponsiveLayout
        }

        default {
            Write-Output "$TargetGridName enhanced version not yet implemented, falling back to original"
            # Fallback to original function
            Initialize-WPFUI -TargetGridName $TargetGridName
        }
    }
}
