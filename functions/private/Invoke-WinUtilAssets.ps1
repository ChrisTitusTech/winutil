function Get-WinUtilAssetGeometry {
  <#
    .SYNOPSIS
        The shapes an asset is made of, as geometry and brush pairs

    .DESCRIPTION
        Kept apart from how they are drawn, so the same definition serves both the live control
        and the rasteriser without the artwork being written out twice.
  #>
  param(
      [Parameter(Mandatory)]
      [string]$Type
  )

  $shapes = New-Object System.Collections.Generic.List[object]
  $blue = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0567ff")
  $grey = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#a3a4a6")

  switch ($Type) {
      'logo' {
          $shapes.Add(@{ Data = @"
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
"@; Brush = $blue })
          $shapes.Add(@{ Data = @"
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
"@; Brush = $blue })
          $shapes.Add(@{ Data = @"
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
"@; Brush = $grey })
      }
      'checkmark' {
          $shapes.Add(@{ Data = "M 1.27,0 A 1.27,1.27 0 1,0 1.27,2.54 A 1.27,1.27 0 1,0 1.27,0"; Brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#39ba00") })
          $shapes.Add(@{ Data = "M 0.873 1.89 L 0.41 1.391 A 0.17 0.17 0 0 1 0.418 1.151 A 0.17 0.17 0 0 1 0.658 1.16 L 1.016 1.543 L 1.583 1.013 A 0.17 0.17 0 0 1 1.599 1 L 1.865 0.751 A 0.17 0.17 0 0 1 2.105 0.759 A 0.17 0.17 0 0 1 2.097 0.999 L 1.282 1.759 L 0.999 2.022 L 0.874 1.888 Z"; Brush = [Windows.Media.Brushes]::White })
      }
      'warning' {
          $shapes.Add(@{ Data = "M 256,0 A 256,256 0 1,0 256,512 A 256,256 0 1,0 256,0"; Brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f41b43") })

          # The mark and the dot are centred against the circle rather than against their own
          # ink, which is why they carry an offset instead of being drawn where they are defined
          $exclamation = [Windows.Media.Geometry]::Parse("M 256 307.2 A 35.89 35.89 0 0 1 220.14 272.74 L 215.41 153.3 A 35.89 35.89 0 0 1 251.27 116 H 260.73 A 35.89 35.89 0 0 1 296.59 153.3 L 291.86 272.74 A 35.89 35.89 0 0 1 256 307.2 Z")
          $exclamationOffset = (512 - $exclamation.Bounds.Width) / 2 - $exclamation.Bounds.X
          $shapes.Add(@{ Geometry = $exclamation; Brush = [Windows.Media.Brushes]::White; OffsetX = $exclamationOffset })

          $dot = New-Object Windows.Media.RectangleGeometry((New-Object Windows.Rect(((512 - 80) / 2), 324.34, 80, 80)), 30, 30)
          $shapes.Add(@{ Geometry = $dot; Brush = [Windows.Media.Brushes]::White })
      }
      default {
          throw "Invalid asset type: $Type"
      }
  }

  foreach ($shape in $shapes) {
      if (-not $shape.Geometry) { $shape.Geometry = [Windows.Media.Geometry]::Parse($shape.Data) }
      if ($shape.OffsetX) {
          $shape.Geometry = $shape.Geometry.Clone()
          $shape.Geometry.Transform = New-Object Windows.Media.TranslateTransform($shape.OffsetX, 0)
      }
  }

  return $shapes
}

function Invoke-WinUtilAssets {
  <#
    .SYNOPSIS
        Returns a WinUtil asset, either as a control or as a bitmap of a given size

    .PARAMETER Size
        The size to produce. With -Render this is the bitmap's real pixel size.

    .PARAMETER Render
        Rasterise rather than return a control.
  #>
  param (
      $type,
      $Size,
      [switch]$render
  )

  if ($render -and $null -ne $sync) {
      if ($null -eq $sync.RenderedAssetCache) {
          $sync.RenderedAssetCache = @{}
      }

      $cacheKey = "$(([string]$type).ToLowerInvariant())|$Size"
      if ($sync.RenderedAssetCache.ContainsKey($cacheKey)) {
          return $sync.RenderedAssetCache[$cacheKey]
      }
  }

  $shapes = Get-WinUtilAssetGeometry -Type $type

  # What the artwork actually occupies. The logo's paths run past the 100 by 100 box they used
  # to be drawn on, so anything sized from that box lost the right and bottom edges.
  $bounds = [Windows.Rect]::Empty
  foreach ($shape in $shapes) {
      $bounds = [Windows.Rect]::Union($bounds, $shape.Geometry.Bounds)
  }

  if (-not $render) {
      $canvas = New-Object Windows.Controls.Canvas
      $canvas.Width = $bounds.Width
      $canvas.Height = $bounds.Height

      foreach ($shape in $shapes) {
          $path = New-Object Windows.Shapes.Path
          $path.Data = $shape.Geometry
          $path.Fill = $shape.Brush
          $path.SetValue([Windows.Controls.Canvas]::LeftProperty, -$bounds.X)
          $path.SetValue([Windows.Controls.Canvas]::TopProperty, -$bounds.Y)
          $canvas.Children.Add($path) | Out-Null
      }

      $viewbox = New-Object Windows.Controls.Viewbox
      $viewbox.Width = $Size
      $viewbox.Height = $Size
      $viewbox.Stretch = [Windows.Media.Stretch]::Uniform
      $viewbox.Child = $canvas
      return $viewbox
  }

  # Drawn straight into a bitmap of the size asked for, so it is rasterised at its final
  # resolution instead of being scaled up from a fixed one
  $pixels = [int][Math]::Max(1, [Math]::Round($Size))
  $scale = [Math]::Min($pixels / $bounds.Width, $pixels / $bounds.Height)
  $offsetX = ($pixels - ($bounds.Width * $scale)) / 2
  $offsetY = ($pixels - ($bounds.Height * $scale)) / 2

  $visual = New-Object Windows.Media.DrawingVisual
  $context = $visual.RenderOpen()
  $context.PushTransform((New-Object Windows.Media.TranslateTransform($offsetX, $offsetY)))
  $context.PushTransform((New-Object Windows.Media.ScaleTransform($scale, $scale)))
  $context.PushTransform((New-Object Windows.Media.TranslateTransform(-$bounds.X, -$bounds.Y)))
  foreach ($shape in $shapes) {
      $context.DrawGeometry($shape.Brush, $null, $shape.Geometry)
  }
  $context.Pop(); $context.Pop(); $context.Pop()
  $context.Close()

  $bitmap = New-Object Windows.Media.Imaging.RenderTargetBitmap($pixels, $pixels, 96, 96, [Windows.Media.PixelFormats]::Pbgra32)
  $bitmap.Render($visual)
  if ($bitmap.CanFreeze) { $bitmap.Freeze() }

  if ($null -ne $sync -and $sync.ContainsKey("RenderedAssetCache")) {
      $sync.RenderedAssetCache[$cacheKey] = $bitmap
  }

  return $bitmap
}
