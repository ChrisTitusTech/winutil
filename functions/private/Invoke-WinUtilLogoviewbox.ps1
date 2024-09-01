function Invoke-WinUtilLogoviewbox {
    param ($Size)

    # Create the Viewbox and set its size
    $LogoViewbox = New-Object Windows.Controls.Viewbox
    $LogoViewbox.Width = $Size
    $LogoViewbox.Height = $Size

    # Define a scale factor for the content inside the Canvas
    $scaleFactor = $Size / 100

    # Part 1
    $LogoPathData1 = @"
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
"@
    $LogoPath1 = New-Object Windows.Shapes.Path
    $LogoPath1.Data = [Windows.Media.Geometry]::Parse($LogoPathData1)
    $LogoPath1.Fill = [Windows.Media.Brushes]::Blue  # Set fill color for left part

    # Part 2
    $LogoPathData2 = @"
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
"@
    $LogoPath2 = New-Object Windows.Shapes.Path
    $LogoPath2.Data = [Windows.Media.Geometry]::Parse($LogoPathData2)
    $LogoPath2.Fill = [Windows.Media.Brushes]::Blue  # Set fill color for right part

    # Part 3
    $LogoPathData3 = @"
           M 20.00,46.00
           C 22.36,47.14 29.67,50.71 31.01,52.63
             32.17,54.30 31.99,57.04 32.00,59.00
             32.04,65.41 31.35,72.16 34.56,78.00
             39.19,86.45 47.10,89.04 55.00,93.31
             57.55,94.69 61.10,97.20 64.00,97.22
             66.50,97.24 69.77,95.36 72.00,94.25
             77.42,91.55 85.51,87.78 89.82,83.68
             95.56,78.20 96.96,70.59 97.00,63.00
             97.01,60.24 96.59,54.63 98.02,52.39
             99.80,49.60 104.95,47.87 108.00,47.00
             108.00,47.00 108.00,67.00 108.00,67.00
             107.90,87.69 97.10,93.85 81.00,103.00
             77.51,104.98 67.66,110.67 64.00,110.52
             61.33,110.41 56.55,107.53 54.00,106.25
             47.21,102.83 37.63,98.57 32.04,93.68
             17.88,81.28 20.00,62.88 20.00,46.00 Z
"@
    $LogoPath3 = New-Object Windows.Shapes.Path
    $LogoPath3.Data = [Windows.Media.Geometry]::Parse($LogoPathData3)
    $LogoPath3.Fill = [Windows.Media.Brushes]::Gray  # Set fill color for bottom part

    # Create a Canvas to hold the paths
    $LogoCanvas = New-Object Windows.Controls.Canvas
    $LogoCanvas.Width = 100
    $LogoCanvas.Height = 100

    # Apply a scale transform to the Canvas content
    $scaleTransform = New-Object Windows.Media.ScaleTransform($scaleFactor, $scaleFactor)
    $LogoCanvas.LayoutTransform = $scaleTransform

    # Add the paths to the Canvas
    $LogoCanvas.Children.Add($LogoPath1) | Out-Null
    $LogoCanvas.Children.Add($LogoPath2) | Out-Null
    $LogoCanvas.Children.Add($LogoPath3) | Out-Null

    # Add the Canvas to the Viewbox
    $LogoViewbox.Child = $LogoCanvas

    return $LogoViewbox
}
