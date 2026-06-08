function Initialize-InstallAppOverlay {
    <#
        .SYNOPSIS
            Creates the overlay with a progress bar and text to indicate that an install or uninstall is in progress
        .PARAMETER TargetGrid
            The Grid element to which the overlay should be added
    #>
    param($TargetGrid)

    $overlay = New-Object Windows.Controls.Border
    $overlay.CornerRadius = New-Object Windows.CornerRadius(10)
    $overlay.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallOverlayBackgroundColor")
    $overlay.Visibility = [Windows.Visibility]::Collapsed

    # Add the overlay to the target Grid on top of the App Area
    $TargetGrid.Children.Add($overlay) | Out-Null
    $sync.InstallAppAreaOverlay = $overlay

    $overlayText = New-Object Windows.Controls.TextBlock
    $overlayText.Text = "Installing apps..."
    $overlayText.HorizontalAlignment = 'Center'
    $overlayText.VerticalAlignment = 'Center'
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
    $overlayText.Background = "Transparent"
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontSizeProperty, "HeaderFontSize")
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontFamilyProperty, "MainFontFamily")
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::FontWeightProperty, "MainFontWeight")
    $overlayText.SetResourceReference([Windows.Controls.TextBlock]::MarginProperty, "MainMargin")
    $sync.InstallAppAreaOverlayText = $overlayText

    $progressbar = New-Object Windows.Controls.ProgressBar
    $progressbar.Name = "ProgressBar"
    $progressbar.Width = 250
    $progressbar.Height = 50
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
    $progressGrid.Margin = "0,10,0,10"
    $progressGrid.Children.Add($progressbar) | Out-Null
    $progressGrid.Children.Add($progressBarTextBlock) | Out-Null

    $overlayStackPanel = New-Object Windows.Controls.StackPanel
    $overlayStackPanel.Orientation = "Vertical"
    $overlayStackPanel.HorizontalAlignment = 'Center'
    $overlayStackPanel.VerticalAlignment = 'Center'
    $overlayStackPanel.Children.Add($overlayText) | Out-Null
    $overlayStackPanel.Children.Add($progressGrid) | Out-Null

    $overlay.Child = $overlayStackPanel
}
