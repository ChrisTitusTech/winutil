    function Initialize-InstallAppArea {
        <#
            .SYNOPSIS
                Creates a [Windows.Controls.ScrollViewer] containing a [Windows.Controls.ItemsControl] which is setup to use Virtualization to only load the visible elements for performance reasons.
                This is used as the parent object for all category and app entries on the install tab
                Used to as part of the Install Tab UI generation

            .PARAMETER TargetElement
                The element to which the AppArea shoud be added

        #>
        param($TargetElement)
        $targetGrid = $sync.Form.FindName($TargetElement)
        $null = $targetGrid.Children.Clear()

        # Create the outer Border for the aren where the apps will be placed
        $Border = New-Object Windows.Controls.Border
        $Border.VerticalAlignment = "Stretch"
        $Border.SetResourceReference([Windows.Controls.Control]::StyleProperty, "BorderStyle")
        $sync.InstallAppAreaBorder = $Border

        # Add a ScrollViewer, because the ItemsControl does not support scrolling by itself
        $scrollViewer = New-Object Windows.Controls.ScrollViewer
        $scrollViewer.VerticalScrollBarVisibility = 'Auto'
        $scrollViewer.HorizontalAlignment = 'Stretch'
        $scrollViewer.VerticalAlignment = 'Stretch'
        $scrollViewer.CanContentScroll = $true
        $sync.InstallAppAreaScrollViewer = $scrollViewer
        $Border.Child = $scrollViewer


        # Add blur effect when the border is disabled
        $blurEffect = New-Object Windows.Media.Effects.BlurEffect
        $blurEffect.Radius = 0

        $scrollViewer.Effect = $blurEffect
        ## Create the ItemsControl, which will be the parent of all the app entries
        $itemsControl = New-Object Windows.Controls.ItemsControl
        $itemsControl.HorizontalAlignment = 'Stretch'
        $itemsControl.VerticalAlignment = 'Stretch'

        # Enable virtualization for the ItemsControl to improve performance (It's hard to test if this is actually working, so if you know what you're doing, please check this)
        $itemsPanelTemplate = New-Object Windows.Controls.ItemsPanelTemplate
        $factory = New-Object Windows.FrameworkElementFactory ([Windows.Controls.VirtualizingStackPanel])
        $itemsPanelTemplate.VisualTree = $factory
        $itemsControl.ItemsPanel = $itemsPanelTemplate
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
        $itemsControl.SetValue([Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [Windows.Controls.VirtualizationMode]::Recycling)

        $scrollViewer.Content = $itemsControl

        $null = $targetGrid.Children.Add($Border)





        # Add a semi-transparent gray overlay when the border is disabled
        $overlay = New-Object Windows.Controls.Border
        # $overlay.Background = New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromARgb(64, 128, 128, 128)) # Semi-transparent gray
        # $overlay.SetResourceReference([Windows.Controls.Control]::StyleProperty, "OverlayStyle")
        $overlay.Visibility = [Windows.Visibility]::Collapsed
        # $overlay.HorizontalAlignment = 'Stretch'
        # $overlay.VerticalAlignment = 'Stretch'
        $overlay.IsHitTestVisible = $false
        $Border.Child = New-Object Windows.Controls.Grid
        $Border.Child.Children.Add($scrollViewer) | Out-Null
        $Border.Child.Children.Add($overlay) | Out-Null
        $sync.InstallAppAreaOverlay = $overlay

        $overlayText = New-Object Windows.Controls.TextBlock
        $overlayText.Text = "Installing apps..."
        $overlayText.HorizontalAlignment = 'Center'
        $overlayText.VerticalAlignment = 'Center'
        $overlayText.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
        $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontSizeProperty, "HeaderFontSize")
        $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontFamilyProperty, "MainFontFamily")
        $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontWeightProperty, "MainFontWeight")
        $overlayText.SetResourceReference([Windows.Controls.TextBlock]::MarginProperty, "MainMargin")
        $overlayText.Tag = "overlayText"
        $sync.InstallAppAreaOverlayText = $overlayText

        $progressbar = New-Object Windows.Controls.ProgressBar
        $progressbar.Name = "ProgressBar"
        $progressbar.Minimum = 0
        $progressbar.Maximum = 100
        $progressbar.Width = 250
        $progressbar.Height = 50
        $progressbar.VerticalAlignment = 'Center'
        $progressbar.HorizontalAlignment = 'Left'


        $sync.ProgressBar = $progressbar

        # Add a TextBlock overlay for the progress bar text
        $progressBarTextBlock = New-Object Windows.Controls.TextBlock
        $progressBarTextBlock.Name = "progressBarTextBlock"
        $progressBarTextBlock.FontWeight = [Windows.FontWeights]::Bold
        $progressBarTextBlock.FontSize = 16
        $progressBarTextBlock.Width = $progressbar.Width
        $progressBarTextBlock.Height = $progressbar.Height
        $progressBarTextBlock.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "ProgressBarTextColor")
        $progressBarTextBlock.TextTrimming = "CharacterEllipsis"

        $progressBarTextBlock.Background = "Transparent"
        $sync.progressBarTextBlock = $progressBarTextBlock

        # Create a Grid to overlay the text on the progress bar
        $progressGrid = New-Object Windows.Controls.Grid
        $progressGrid.Width = $progressbar.Width
        $progressGrid.Height = $progressbar.Height
        $progressGrid.Children.Add($progressbar) | Out-Null
        $progressGrid.Children.Add($progressBarTextBlock) | Out-Null

        $overlayStackPanel = New-Object Windows.Controls.StackPanel
        $overlayStackPanel.Orientation = "Vertical"
        $overlayStackPanel.HorizontalAlignment = 'Stretch'
        $overlayStackPanel.VerticalAlignment = 'Stretch'
        $overlayStackPanel.HorizontalAlignment = 'Center'
        $overlayStackPanel.VerticalAlignment = 'Center'
        $overlayStackPanel.Children.Add($overlayText) | Out-Null
        $overlayStackPanel.Children.Add($progressGrid) | Out-Null

        $overlay.Child = $overlayStackPanel

        return $itemsControl
    }
