function Show-CustomDialog {
    <#
    .SYNOPSIS
    Displays a custom dialog box with an image, heading, message, and an OK button.
    
    .DESCRIPTION
    This function creates a custom dialog box with the specified message and additional elements such as an image, heading, and an OK button. The dialog box is designed with a green border, rounded corners, and a black background.
    
    .PARAMETER Message
    The message to be displayed in the dialog box.

    .PARAMETER Width
    The width of the custom dialog window.

    .PARAMETER Height
    The height of the custom dialog window.
    
    .EXAMPLE
    Show-CustomDialog -Message "This is a custom dialog with a message and an image above." -Width 300 -Height 200
    
    #>
    param(
        [string]$Message,
        [int]$Width = 300,
        [int]$Height = 200
    )

    Add-Type -AssemblyName PresentationFramework

    # Define theme colors
    $foregroundColor = [Windows.Media.Brushes]::White
    $backgroundColor = [Windows.Media.Brushes]::Black
    $font = New-Object Windows.Media.FontFamily("Consolas")
    $borderColor = [Windows.Media.Brushes]::Green
    $buttonBackgroundColor = [Windows.Media.Brushes]::Black
    $buttonForegroundColor = [Windows.Media.Brushes]::White
    $shadowColor = [Windows.Media.ColorConverter]::ConvertFromString("#AAAAAAAA")

    # Create a custom dialog window
    $dialog = New-Object Windows.Window
    $dialog.Title = "About"
    $dialog.Height = $Height
    $dialog.Width = $Width
    $dialog.Margin = New-Object Windows.Thickness(10)  # Add margin to the entire dialog box
    $dialog.WindowStyle = [Windows.WindowStyle]::None  # Remove title bar and window controls
    $dialog.ResizeMode = [Windows.ResizeMode]::NoResize  # Disable resizing
    $dialog.WindowStartupLocation = [Windows.WindowStartupLocation]::CenterScreen  # Center the window
    $dialog.Foreground = $foregroundColor
    $dialog.Background = $backgroundColor
    $dialog.FontFamily = $font

    # Create a Border for the green edge with rounded corners
    $border = New-Object Windows.Controls.Border
    $border.BorderBrush = $borderColor
    $border.BorderThickness = New-Object Windows.Thickness(1)  # Adjust border thickness as needed
    $border.CornerRadius = New-Object Windows.CornerRadius(10)  # Adjust the radius for rounded corners

    # Create a drop shadow effect
    $dropShadow = New-Object Windows.Media.Effects.DropShadowEffect
    $dropShadow.Color = $shadowColor
    $dropShadow.Direction = 270
    $dropShadow.ShadowDepth = 5
    $dropShadow.BlurRadius = 10

    # Apply drop shadow effect to the border
    $dialog.Effect = $dropShadow

    $dialog.Content = $border

    # Create a grid for layout inside the Border
    $grid = New-Object Windows.Controls.Grid
    $border.Child = $grid

    # Add the following line to show gridlines
    #$grid.ShowGridLines = $true

    # Add the following line to set the background color of the grid
    $grid.Background = [Windows.Media.Brushes]::Transparent
    # Add the following line to make the Grid stretch
    $grid.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch
    $grid.VerticalAlignment = [Windows.VerticalAlignment]::Stretch

    # Add the following line to make the Border stretch
    $border.HorizontalAlignment = [Windows.HorizontalAlignment]::Stretch
    $border.VerticalAlignment = [Windows.VerticalAlignment]::Stretch


    # Set up Row Definitions
    $row0 = New-Object Windows.Controls.RowDefinition
    $row0.Height = [Windows.GridLength]::Auto

    $row1 = New-Object Windows.Controls.RowDefinition
    $row1.Height = [Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)

    $row2 = New-Object Windows.Controls.RowDefinition
    $row2.Height = [Windows.GridLength]::Auto

    # Add Row Definitions to Grid
    $grid.RowDefinitions.Add($row0)
    $grid.RowDefinitions.Add($row1)
    $grid.RowDefinitions.Add($row2)
        
    # Add StackPanel for horizontal layout with margins
    $stackPanel = New-Object Windows.Controls.StackPanel
    $stackPanel.Margin = New-Object Windows.Thickness(10)  # Add margins around the stack panel
    $stackPanel.Orientation = [Windows.Controls.Orientation]::Horizontal
    $stackPanel.HorizontalAlignment = [Windows.HorizontalAlignment]::Left  # Align to the left
    $stackPanel.VerticalAlignment = [Windows.VerticalAlignment]::Top  # Align to the top

    $grid.Children.Add($stackPanel)
    [Windows.Controls.Grid]::SetRow($stackPanel, 0)  # Set the row to the second row (0-based index)

    $viewbox = New-Object Windows.Controls.Viewbox
    $viewbox.Width = 25
    $viewbox.Height = 25
    
    # Combine the paths into a single string
#     $cttLogoPath = @"
#     M174 1094 c-4 -14 -4 -55 -2 -92 3 -57 9 -75 41 -122 41 -60 45 -75 22 -84 -25 -9 -17 -21 30 -44 l45 -22 0 -103 c0 -91 3 -109 26 -155 30 -60 65 -87 204 -157 l95 -48 110 58 c184 96 205 127 205 293 l0 108 45 22 c47 23 55 36 30 46 -22 8 -18 30 9 63 13 16 34 48 46 71 20 37 21 52 15 116 l-6 73 -69 -23 c-38 -12 -137 -59 -220 -103 -82 -45 -160 -81 -171 -81 -12 0 -47 15 -78 34 -85 51 -239 127 -309 151 l-62 22 -6 -23z m500 -689 c20 -8 36 -19 36 -24 0 -18 -53 -51 -80 -51 -28 0 -80 33 -80 51 0 10 55 38 76 39 6 0 28 -7 48 -15z
#     M177 711 c-19 -88 4 -242 49 -318 43 -74 107 -127 232 -191 176 -90 199 -84 28 7 -169 91 -214 129 -258 220 -29 58 -32 74 -37 190 -4 90 -8 116 -14 92z
#     M1069 610 c-4 -131 -5 -137 -38 -198 -43 -79 -89 -119 -210 -181 -53 -27 -116 -61 -141 -76 -74 -43 -6 -20 115 40 221 109 296 217 294 425 -1 144 -16 137 -20 -10z
# "@
$cttLogoPath = @"
           M 18.00,14.00
           C 18.00,14.00 45.00,27.74 45.00,27.74
             45.00,27.74 57.40,34.63 57.40,34.63
             57.40,34.63 59.00,43.00 59.00,43.00
             59.00,43.00 59.00,83.00 59.00,83.00
             55.35,81.66 46.99,77.79 44.72,74.79
             41.17,70.10 42.01,59.80 42.00,54.00
             42.00,51.62 42.20,48.29 40.98,46.21
             38.34,41.74 25.78,38.60 21.28,33.79
             16.81,29.02 18.00,20.20 18.00,14.00 Z
           M 107.00,14.00
           C 109.01,19.06 108.93,30.37 104.66,34.21
             100.47,37.98 86.38,43.10 84.60,47.21
             83.94,48.74 84.01,51.32 84.00,53.00
             83.97,57.04 84.46,68.90 83.26,72.00
             81.06,77.70 72.54,81.42 67.00,83.00
             67.00,83.00 67.00,43.00 67.00,43.00
             67.00,43.00 67.99,35.63 67.99,35.63
             67.99,35.63 80.00,28.26 80.00,28.26
             80.00,28.26 107.00,14.00 107.00,14.00 Z
           M 19.00,46.00
           C 21.36,47.14 28.67,50.71 30.01,52.63
             31.17,54.30 30.99,57.04 31.00,59.00
             31.04,65.41 30.35,72.16 33.56,78.00
             38.19,86.45 46.10,89.04 54.00,93.31
             56.55,94.69 60.10,97.20 63.00,97.22
             65.50,97.24 68.77,95.36 71.00,94.25
             76.42,91.55 84.51,87.78 88.82,83.68
             94.56,78.20 95.96,70.59 96.00,63.00
             96.01,60.24 95.59,54.63 97.02,52.39
             98.80,49.60 103.95,47.87 107.00,47.00
             107.00,47.00 107.00,67.00 107.00,67.00
             106.90,87.69 96.10,93.85 80.00,103.00
             76.51,104.98 66.66,110.67 63.00,110.52
             60.33,110.41 55.55,107.53 53.00,106.25
             46.21,102.83 36.63,98.57 31.04,93.68
             16.88,81.28 19.00,62.88 19.00,46.00 Z
"@
    
    # Add SVG path
    $svgPath = New-Object Windows.Shapes.Path
    $svgPath.Data = [Windows.Media.Geometry]::Parse($cttLogoPath)
    $svgPath.Fill = $foregroundColor  # Set fill color to white

    # Add SVG path to Viewbox
    $viewbox.Child = $svgPath
    
    # Add SVG path to the stack panel
    $stackPanel.Children.Add($viewbox)

    # Add "Winutil" text
    $winutilTextBlock = New-Object Windows.Controls.TextBlock
    $winutilTextBlock.Text = "Winutil"
    $winutilTextBlock.FontSize = 18  # Adjust font size as needed
    $winutilTextBlock.Foreground = $foregroundColor
    $winutilTextBlock.Margin = New-Object Windows.Thickness(10, 5, 10, 5)  # Add margins around the text block
    $stackPanel.Children.Add($winutilTextBlock)

    # Add TextBlock for information with text wrapping and margins
    $messageTextBlock = New-Object Windows.Controls.TextBlock
    $messageTextBlock.Text = $Message
    $messageTextBlock.TextWrapping = [Windows.TextWrapping]::Wrap  # Enable text wrapping
    $messageTextBlock.HorizontalAlignment = [Windows.HorizontalAlignment]::Left
    $messageTextBlock.VerticalAlignment = [Windows.VerticalAlignment]::Top
    $messageTextBlock.Margin = New-Object Windows.Thickness(10)  # Add margins around the text block
    $grid.Children.Add($messageTextBlock)
    [Windows.Controls.Grid]::SetRow($messageTextBlock, 1)  # Set the row to the second row (0-based index)

    # Add OK button
    $okButton = New-Object Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Width = 80
    $okButton.Height = 30
    $okButton.HorizontalAlignment = [Windows.HorizontalAlignment]::Center
    $okButton.VerticalAlignment = [Windows.VerticalAlignment]::Bottom
    $okButton.Margin = New-Object Windows.Thickness(0, 0, 0, 10)
    $okButton.Background = $buttonBackgroundColor
    $okButton.Foreground = $buttonForegroundColor
    $okButton.BorderBrush = $borderColor
    $okButton.Add_Click({
        $dialog.Close()
    })
    $grid.Children.Add($okButton)
    [Windows.Controls.Grid]::SetRow($okButton, 2)  # Set the row to the third row (0-based index)

    # Handle Escape key press to close the dialog
    $dialog.Add_KeyDown({
        if ($_.Key -eq 'Escape') {
            $dialog.Close()
        }
    })

    # Set the OK button as the default button (activated on Enter)
    $okButton.IsDefault = $true

    # Show the custom dialog
    $dialog.ShowDialog()
}
