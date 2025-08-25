function Initialize-InstallAppArea {
    <#
        .SYNOPSIS
            Enhanced version of Initialize-InstallAppArea with improved responsive design and performance.
            Creates a responsive ScrollViewer with optimized layout for applications grid.

        .PARAMETER TargetElement
            The element to which the AppArea should be added
        .PARAMETER UseResponsiveLayout
            Enable responsive WrapPanel layout instead of traditional ItemsControl (default: true)
    #>
    param(
        $TargetElement,
        [bool]$UseResponsiveLayout = $true
    )

    $targetGrid = $sync.Form.FindName($TargetElement)
    $null = $targetGrid.Children.Clear()

    # Create the outer Border for the app area with enhanced styling
    $Border = New-Object Windows.Controls.Border
    $Border.VerticalAlignment = "Stretch"
    $Border.HorizontalAlignment = "Stretch"
    $Border.SetResourceReference([Windows.Controls.Control]::StyleProperty, "BorderStyle")
    $Border.Padding = '5'
    $sync.InstallAppAreaBorder = $Border

    # Enhanced ScrollViewer with better performance settings
    $scrollViewer = New-Object Windows.Controls.ScrollViewer
    $scrollViewer.VerticalScrollBarVisibility = 'Auto'
    $scrollViewer.HorizontalScrollBarVisibility = 'Disabled'
    $scrollViewer.HorizontalAlignment = 'Stretch'
    $scrollViewer.VerticalAlignment = 'Stretch'
    $scrollViewer.CanContentScroll = $false
    $scrollViewer.IsDeferredScrollingEnabled = $true
    $scrollViewer.SetValue([Windows.Controls.ScrollViewer]::PanningModeProperty, [Windows.Controls.PanningMode]::VerticalOnly)
    $sync.InstallAppAreaScrollViewer = $scrollViewer
    $Border.Child = $scrollViewer

    # Initialize blur effect for install/uninstall progress
    $blurEffect = New-Object Windows.Media.Effects.BlurEffect
    $blurEffect.Radius = 0
    $scrollViewer.Effect = $blurEffect

    if ($UseResponsiveLayout) {
        # Enhanced responsive layout with improved performance
        $mainContent = New-Object Windows.Controls.StackPanel
        $mainContent.Orientation = 'Vertical'
        $mainContent.HorizontalAlignment = 'Stretch'
        $mainContent.Margin = '10,5,10,15'
        $scrollViewer.Content = $mainContent
        $sync.InstallAppMainContent = $mainContent
    } else {
        # Traditional ItemsControl with enhanced virtualization
        $itemsControl = New-Object Windows.Controls.ItemsControl
        $itemsControl.HorizontalAlignment = 'Stretch'
        $itemsControl.VerticalAlignment = 'Stretch'
        $scrollViewer.Content = $itemsControl

        # Enhanced virtualization setup
        $itemsPanelTemplate = New-Object Windows.Controls.ItemsPanelTemplate
        $factory = New-Object Windows.FrameworkElementFactory ([Windows.Controls.VirtualizingStackPanel])
        $factory.SetValue([Windows.Controls.VirtualizingStackPanel]::OrientationProperty, [Windows.Controls.Orientation]::Vertical)
        $factory.SetValue([Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [Windows.Controls.VirtualizationMode]::Recycling)
        $itemsPanelTemplate.VisualTree = $factory
        $itemsControl.ItemsPanel = $itemsPanelTemplate

        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [Windows.Controls.VirtualizationMode]::Recycling)
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::IsItemsHostProperty, $true)
        $sync.InstallAppMainContent = $itemsControl
    }

    # Add the Border containing the App Area to the target Grid
    $targetGrid.Children.Add($Border) | Out-Null

    # Enhanced overlay with better styling
    $overlay = New-Object Windows.Controls.Border
    $overlay.CornerRadius = New-Object Windows.CornerRadius(12)
    $overlay.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallOverlayBackgroundColor")
    $overlay.Visibility = [Windows.Visibility]::Collapsed
    $overlay.BorderThickness = '2'
    $overlay.SetResourceReference([Windows.Controls.Control]::BorderBrushProperty, "MainForegroundColor")

    $targetGrid.Children.Add($overlay) | Out-Null
    $sync.InstallAppAreaOverlay = $overlay

    # Enhanced overlay content
    $overlayText = New-Object Windows.Controls.TextBlock
    $overlayText.Text = "Installing applications..."
    $overlayText.HorizontalAlignment = 'Center'
    $overlayText.VerticalAlignment = 'Center'
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
    $overlayText.Background = "Transparent"
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontSizeProperty, "HeaderFontSize")
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontFamilyProperty, "MainFontFamily")
    $overlayText.FontWeight = 'SemiBold'
    $overlayText.TextAlignment = 'Center'
    $sync.InstallAppAreaOverlayText = $overlayText

    # Enhanced progress bar
    $progressbar = New-Object Windows.Controls.ProgressBar
    $progressbar.Name = "ProgressBar"
    $progressbar.Width = 300
    $progressbar.Height = 8
    $progressbar.SetResourceReference([Windows.Controls.Control]::StyleProperty, "ModernProgressBarStyle")
    $sync.ProgressBar = $progressbar

    # Progress text
    $progressBarTextBlock = New-Object Windows.Controls.TextBlock
    $progressBarTextBlock.Name = "progressBarTextBlock"
    $progressBarTextBlock.FontWeight = [Windows.FontWeights]::Normal
    $progressBarTextBlock.FontSize = 14
    $progressBarTextBlock.Width = 300
    $progressBarTextBlock.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
    $progressBarTextBlock.TextTrimming = "CharacterEllipsis"
    $progressBarTextBlock.Background = "Transparent"
    $progressBarTextBlock.TextAlignment = 'Center'
    $progressBarTextBlock.Margin = '0,8,0,0'
    $sync.progressBarTextBlock = $progressBarTextBlock

    # Progress container with modern styling
    $progressContainer = New-Object Windows.Controls.StackPanel
    $progressContainer.Orientation = "Vertical"
    $progressContainer.HorizontalAlignment = 'Center'
    $progressContainer.VerticalAlignment = 'Center'
    $progressContainer.Margin = '20'

    $progressContainer.Children.Add($overlayText) | Out-Null
    $progressContainer.Children.Add($progressbar) | Out-Null
    $progressContainer.Children.Add($progressBarTextBlock) | Out-Null

    $overlay.Child = $progressContainer

    return $sync.InstallAppMainContent
}
