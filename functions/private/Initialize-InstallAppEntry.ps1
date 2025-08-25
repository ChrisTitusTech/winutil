function Initialize-InstallAppEntry {
    <#
        .SYNOPSIS
            Enhanced version of Initialize-InstallAppEntry with modern styling, better interaction, and responsive design.
            Creates visually appealing app entries with improved hover effects and accessibility.

        .PARAMETER TargetElement
            The WrapPanel into which the App should be placed
        .PARAMETER AppKey
            The Key of the app inside the applications hashtable
        .PARAMETER Apps
            The applications hashtable reference
        .PARAMETER ItemWidth
            The width for the app item (optional, uses parent container width if not specified)
    #>
    param(
        [Windows.Controls.WrapPanel]$TargetElement,
        $AppKey,
        $Apps,
        [double]$ItemWidth = 0
    )

    # Get app information
    $appInfo = $Apps.$AppKey

    # Create enhanced outer border with modern styling
    $border = Create-AppBorder -AppKey $AppKey -ItemWidth $ItemWidth

    # Create enhanced checkbox
    $checkBox = Create-AppCheckbox -AppKey $AppKey

    # Create content layout
    $contentStack = Create-AppContent -AppInfo $appInfo

    # Create horizontal layout for checkbox and content
    $horizontalStack = Create-AppLayout -CheckBox $checkBox -ContentStack $contentStack

    # Add package manager indicators if available
    Add-PackageManagerIndicators -AppInfo $appInfo -ContentStack $contentStack

    # Finalize layout
    $horizontalStack.Children.Add($contentStack) | Out-Null
    $border.Child = $horizontalStack

    # Add event handlers
    Add-CheckboxEventHandlers -CheckBox $checkBox
    Add-BorderEventHandlers -Border $border

    # Add tooltip for truncated descriptions
    Add-DescriptionTooltip -Border $border -AppInfo $appInfo

    # Configure accessibility
    Set-AccessibilityProperties -Border $border -CheckBox $checkBox -AppInfo $appInfo

    # Add to target element
    $TargetElement.Children.Add($border) | Out-Null

    return $checkBox
}

function Create-AppBorder {
    param($AppKey, $ItemWidth)

    $border = New-Object Windows.Controls.Border
    $border.Style = $sync.Form.Resources.AppEntryBorderStyle
    $border.Tag = $AppKey
    $border.Margin = '6,4,6,4'
    $border.Padding = '12,10,12,10'
    $border.CornerRadius = '8'
    $border.Cursor = 'Hand'

    # Enhanced border styling
    $border.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
    $border.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
    $border.BorderThickness = '1'

    # Set width and consistent height for responsive layout
    if ($ItemWidth -gt 0) {
        $border.Width = $ItemWidth - 12  # Account for margins
        $border.Height = 115  # Reduced height to remove empty space
        $border.HorizontalAlignment = 'Stretch'
        $border.VerticalAlignment = 'Top'
    }

    return $border
}

function Create-AppCheckbox {
    param($AppKey)

    $checkBox = New-Object Windows.Controls.CheckBox
    $checkBox.Name = $AppKey
    $checkBox.Style = $sync.Form.Resources.AppEntryCheckboxStyle
    $checkBox.HorizontalAlignment = 'Left'
    $checkBox.VerticalAlignment = 'Top'

    return $checkBox
}

function Create-AppContent {
    param($AppInfo)

    # Create content container
    $contentStack = New-Object Windows.Controls.StackPanel
    $contentStack.Orientation = 'Vertical'
    $contentStack.HorizontalAlignment = 'Stretch'
    $contentStack.VerticalAlignment = 'Stretch'

    # Enhanced app name with better typography - more prominent
    $appName = New-Object Windows.Controls.TextBlock
    $appName.Name = "AppName"
    $appName.Style = $sync.Form.Resources.AppEntryNameStyle
    $appName.Text = $appInfo.content
    $appName.TextWrapping = 'Wrap'
    $appName.TextTrimming = 'CharacterEllipsis'
    $appName.MaxHeight = 40
    $appName.FontWeight = 'Bold'  # Changed from SemiBold to Bold for more prominence
    $appName.FontSize = 13  # Slightly larger font size
    $appName.Margin = '0,0,0,4'
    $appName.Background = 'Transparent'

    # Add app description with consistent height
    $appDescription = New-Object Windows.Controls.TextBlock
    $appDescription.Name = "AppDescription"
    $appDescription.Text = if ($appInfo.description -and $appInfo.description.Length -gt 0) {
        $appInfo.description
    } else { "" }
    $appDescription.FontSize = 11
    $appDescription.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
    $appDescription.TextWrapping = 'Wrap'
    $appDescription.TextTrimming = 'CharacterEllipsis'
    $appDescription.MaxHeight = 44  # Reduced to fit the smaller card height
    $appDescription.Margin = '0,0,0,6'
    $appDescription.Background = 'Transparent'

    # Add content to stack
    $contentStack.Children.Add($appName) | Out-Null
    if ($appDescription.Text -ne "") {
        $contentStack.Children.Add($appDescription) | Out-Null
    }

    return $contentStack
}

function Create-AppLayout {
    param($CheckBox, $ContentStack)

    # Create horizontal layout for checkbox and content
    $horizontalStack = New-Object Windows.Controls.DockPanel
    $horizontalStack.HorizontalAlignment = 'Stretch'
    $horizontalStack.VerticalAlignment = 'Stretch'

    # Position checkbox on the left
    $checkBox.SetValue([Windows.Controls.DockPanel]::DockProperty, [Windows.Controls.Dock]::Left)
    $checkBox.VerticalAlignment = 'Top'
    $checkBox.Margin = '0,2,8,0'
    $horizontalStack.Children.Add($checkBox) | Out-Null

    return $horizontalStack
}

function Add-PackageManagerIndicators {
    param($AppInfo, $ContentStack)

    # Add package manager indicators if available
    if ($appInfo.winget -or $appInfo.choco) {
        $pmStack = New-Object Windows.Controls.StackPanel
        $pmStack.Orientation = 'Horizontal'
        $pmStack.Margin = '0,4,0,0'

        # Add "Sources:" label
        $sourcesLabel = New-Object Windows.Controls.TextBlock
        $sourcesLabel.Text = "Sources:"
        $sourcesLabel.FontSize = 10
        $sourcesLabel.FontWeight = 'Normal'
        $sourcesLabel.SetResourceReference([Windows.Controls.Control]::ForegroundProperty , "MainForegroundColor")
        $sourcesLabel.Background = 'Transparent'
        $sourcesLabel.Margin = '0,0,6,0'
        $sourcesLabel.Opacity = 0.8
        $pmStack.Children.Add($sourcesLabel) | Out-Null

        # Check which sources are available
        $hasWinget = ($appInfo.winget -and $appInfo.winget -ne "na")
        $hasChoco = ($appInfo.choco -and $appInfo.choco -ne "na")

        if ($hasWinget) {
            $wingetIcon = New-Object Windows.Controls.TextBlock
            $wingetIcon.Text = "Winget"
            $wingetIcon.FontSize = 10
            $wingetIcon.FontWeight = 'Bold'
            $wingetIcon.ToolTip = "Available via Winget"
            $wingetIcon.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $wingetIcon.Background = 'Transparent'
            $wingetIcon.Margin = '0,0,0,0'
            $pmStack.Children.Add($wingetIcon) | Out-Null
        }

        # Add dash separator if both sources are available
        if ($hasWinget -and $hasChoco) {
            $dashIcon = New-Object Windows.Controls.TextBlock
            $dashIcon.Text = " - "
            $dashIcon.FontSize = 10
            $dashIcon.FontWeight = 'Normal'
            $dashIcon.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $dashIcon.Background = 'Transparent'
            $dashIcon.Margin = '0,0,0,0'
            $pmStack.Children.Add($dashIcon) | Out-Null
        }

        if ($hasChoco) {
            $chocoIcon = New-Object Windows.Controls.TextBlock
            $chocoIcon.Text = "Choco"
            $chocoIcon.FontSize = 10
            $chocoIcon.FontWeight = 'Bold'
            $chocoIcon.ToolTip = "Available via Chocolatey"
            $chocoIcon.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $chocoIcon.Background = 'Transparent'
            $chocoIcon.Margin = '0,0,0,0'
            $pmStack.Children.Add($chocoIcon) | Out-Null
        }

        $contentStack.Children.Add($pmStack) | Out-Null
    }
}

function Add-CheckboxEventHandlers {
    param($CheckBox)

    $checkBox.Add_Checked({
        Invoke-WPFSelectedAppsUpdate -type "Add" -checkbox $this
        # In enhanced layout: Checkbox -> DockPanel -> Border
        $borderElement = $this.Parent.Parent
        if ($borderElement -and $borderElement -is [Windows.Controls.Border]) {
            # Use same colors as navigation selected state
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "ToggleButtonOnColor")
            $borderElement.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "ToggleButtonOnColor")
            $borderElement.BorderThickness = '2'

            # Find and update text color to white (same as navigation selected)
            # Structure: Border -> HorizontalStackPanel -> StackPanel -> TextBlocks
            $horizontalStack = $borderElement.Child
            if ($horizontalStack -and $horizontalStack -is [Windows.Controls.StackPanel]) {
                $contentStack = $horizontalStack.Children | Where-Object { $_ -is [Windows.Controls.StackPanel] } | Select-Object -First 1
                if ($contentStack) {
                    $textBlocks = $contentStack.Children | Where-Object { $_ -is [Windows.Controls.TextBlock] }
                    foreach ($tb in $textBlocks) {
                        $tb.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainBackgroundColor")
                    }
                }
            }

            # Add selected visual effect
            $transform = New-Object Windows.Media.ScaleTransform(0.99, 0.99)
            $borderElement.RenderTransform = $transform
            $borderElement.RenderTransformOrigin = '0.5,0.5'
        }
    })

    $checkBox.Add_Unchecked({
        Invoke-WPFSelectedAppsUpdate -type "Remove" -checkbox $this
        # In enhanced layout: Checkbox -> DockPanel -> Border
        $borderElement = $this.Parent.Parent
        if ($borderElement -and $borderElement -is [Windows.Controls.Border]) {
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
            $borderElement.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
            $borderElement.BorderThickness = '1'

            # Find and reset text color to normal
            # Structure: Border -> HorizontalStackPanel -> StackPanel -> TextBlocks
            $horizontalStack = $borderElement.Child
            if ($horizontalStack -and $horizontalStack -is [Windows.Controls.StackPanel]) {
                $contentStack = $horizontalStack.Children | Where-Object { $_ -is [Windows.Controls.StackPanel] } | Select-Object -First 1
                if ($contentStack) {
                    $textBlocks = $contentStack.Children | Where-Object { $_ -is [Windows.Controls.TextBlock] }
                    foreach ($tb in $textBlocks) {
                        $tb.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
                    }
                }
            }

            # Reset visual effects
            $borderElement.RenderTransform = $null
        }
    })
}

function Add-BorderEventHandlers {
    param($Border)

    # Enhanced hover animations and interactions
    $border.Add_MouseEnter({
        if (($sync.$($this.Tag).IsChecked) -eq $false) {
            $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallHighlightedColor")
            $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "MainForegroundColor")
            $this.BorderThickness = '2'
            # Subtle scale effect
            $transform = New-Object Windows.Media.ScaleTransform(1.01, 1.01)
            $this.RenderTransform = $transform
            $this.RenderTransformOrigin = '0.5,0.5'
        }
    })

    $border.Add_MouseLeave({
        if (($sync.$($this.Tag).IsChecked) -eq $false) {
            $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
            $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
            $this.BorderThickness = '1'
            # Reset scale
            $this.RenderTransform = $null
        }
    })

    # Enhanced click interaction
    $border.Add_MouseLeftButtonUp({
        # Find the checkbox in the border's child structure
        $appKey = $this.Tag
        if ($sync.$appKey -and $sync.$appKey -is [Windows.Controls.CheckBox]) {
            $sync.$appKey.IsChecked = -not $sync.$appKey.IsChecked
        }
    })

    # Right-click context menu
    $border.Add_MouseRightButtonUp({
        $sync.appPopupSelectedApp = $this.Tag
        $sync.appPopup.PlacementTarget = $this
        $sync.appPopup.IsOpen = $true
    })

    # Add visual focus indicators for keyboard navigation
    $border.Focusable = $true
    $border.Add_GotFocus({
        $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "MainForegroundColor")
        $this.BorderThickness = '2'
    })

    $border.Add_LostFocus({
        if (($sync.$($this.Tag).IsChecked) -eq $false) {
            $this.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "BorderColor")
            $this.BorderThickness = '1'
        }
    })

    # Add keyboard support
    $border.Add_KeyDown({
        param($source, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Space -or $e.Key -eq [System.Windows.Input.Key]::Enter) {
            $childCheckbox = ($source.Child.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] })[0]
            if ($childCheckbox) {
                $childCheckbox.IsChecked = -not $childCheckbox.IsChecked
            }
            $e.Handled = $true
        }
    })
}

function Add-DescriptionTooltip {
    param($Border, $AppInfo)

    # Add tooltip only if description is truncated due to height constraint
    if ($appInfo.description -and $appInfo.description.Length -gt 0) {
        # More accurate detection of text truncation
        # Check if description would be truncated based on available space and font size
        $availableHeight = 44  # MaxHeight of description
        $lineHeight = 15       # Approximate line height for 11px font
        $maxLines = [Math]::Floor($availableHeight / $lineHeight)
        $avgCharsPerLine = 45  # Average characters per line for this width
        $estimatedLines = [Math]::Ceiling($appInfo.description.Length / $avgCharsPerLine)

        # Also check for long words that might cause wrapping
        $hasLongWords = $appInfo.description -match '\S{25,}'  # Words longer than 25 chars

        if ($estimatedLines -gt $maxLines -or $hasLongWords) {
            $border.ToolTip = $appInfo.description
        }
    }
}

function Set-AccessibilityProperties {
    param($Border, $CheckBox, $AppInfo)

    # Enhanced accessibility
    $checkBox.SetValue([Windows.Automation.AutomationProperties]::NameProperty, $appInfo.content)
    $border.SetValue([Windows.Automation.AutomationProperties]::NameProperty, $appInfo.content)
}
