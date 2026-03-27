function Initialize-InstallAppArea {
    <#
        .SYNOPSIS
            Creates a [Windows.Controls.ScrollViewer] containing a [Windows.Controls.ItemsControl] which is setup to use Virtualization to only load the visible elements for performance reasons.
            This is used as the parent object for all category and app entries on the install tab
            Used to as part of the Install Tab UI generation

        .PARAMETER TargetElement
            The element to which the AppArea should be added

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

    # Initialize the Blur Effect for the ScrollViewer
    $blurEffect = New-Object Windows.Media.Effects.BlurEffect
    $blurEffect.Radius = 0
    $scrollViewer.Effect = $blurEffect

    ## Create the ItemsControl, which will be the parent of all the app entries
    $itemsControl = New-Object Windows.Controls.ItemsControl
    $itemsControl.HorizontalAlignment = 'Stretch'
    $itemsControl.VerticalAlignment = 'Stretch'
    $scrollViewer.Content = $itemsControl

    # Use WrapPanel to create dynamic columns based on AppEntryWidth and window width
    $itemsPanelTemplate = New-Object Windows.Controls.ItemsPanelTemplate
    $factory = New-Object Windows.FrameworkElementFactory ([Windows.Controls.WrapPanel])
    $factory.SetValue([Windows.Controls.WrapPanel]::OrientationProperty, [Windows.Controls.Orientation]::Horizontal)
    $factory.SetValue([Windows.Controls.WrapPanel]::HorizontalAlignmentProperty, [Windows.HorizontalAlignment]::Left)
    $itemsPanelTemplate.VisualTree = $factory
    $itemsControl.ItemsPanel = $itemsPanelTemplate

    # Add the Border containing the App Area to the target Grid
    $targetGrid.Children.Add($Border) | Out-Null

    # Create progress bar objects (hidden, not displayed as overlay)
    $progressbar = New-Object Windows.Controls.ProgressBar
    $progressbar.Name = "ProgressBar"
    $progressbar.Width = 250
    $progressbar.Height = 50
    $sync.ProgressBar = $progressbar

    # Add a TextBlock for the progress bar text
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

    return $itemsControl
}
