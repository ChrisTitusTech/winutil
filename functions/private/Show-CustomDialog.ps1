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
           M 4 8 L 10 1 L 13 0 L 12 3 L 5 9 C 6 10 6 11 7 10 C 7 11 8 12 7 12 A 1.42 1.42 0 0 1 6 13 A 5 5 0 0 0 4 10 Q 3.5 9.9 3.5 10.5 T 2 11.8 T 1.2 11 T 2.5 9.5 T 3 9 A 5 5 90 0 0 0 7 A 1.42 1.42 0 0 1 1 6 C 1 5 2 6 3 6 C 2 7 3 7 4 8 M 10 1 L 10 3 L 12 3 L 10.2 2.8 L 10 1
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
