<#
    .SYNOPSIS
        Adds or replaces an app's bundled icon in config/icons.json

    .DESCRIPTION
        Scales an image (PNG, ICO, JPG, GIF or BMP) to fit a 64x64 transparent canvas and stores it
        as a base64 PNG under the app's key. Entries are written in config/applications.json order.
        An empty value is a deliberate "no icon" and keeps the letter tile.

    .EXAMPLE
        .\tools\New-WinUtilIcon.ps1 -Key brave -Path C:\Downloads\brave.png
#>
param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Path
)

Add-Type -AssemblyName System.Drawing

$size = 64
$margin = 0.04
$configRoot = Join-Path $PSScriptRoot "..\config"
$applications = Get-Content (Join-Path $configRoot "applications.json") -Raw | ConvertFrom-Json
if (-not $applications.PSObject.Properties[$Key]) { throw "'$Key' is not a key in config/applications.json." }

$source = [Drawing.Image]::FromFile((Resolve-Path $Path))
$canvas = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    $graphics = [Drawing.Graphics]::FromImage($canvas)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $fit = $size * (1 - 2 * $margin) / [Math]::Max($source.Width, $source.Height)
    $width = [int][Math]::Round($source.Width * $fit)
    $height = [int][Math]::Round($source.Height * $fit)
    $graphics.DrawImage($source, [int](($size - $width) / 2), [int](($size - $height) / 2), $width, $height)
    $stream = [IO.MemoryStream]::new()
    $canvas.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
    $encoded = [Convert]::ToBase64String($stream.ToArray())
} finally {
    $source.Dispose(); $canvas.Dispose()
}

$iconsPath = Join-Path $configRoot "icons.json"
$icons = Get-Content $iconsPath -Raw | ConvertFrom-Json
$lines = foreach ($name in $applications.PSObject.Properties.Name) {
    $value = if ($name -eq $Key) { $encoded } elseif ($icons.PSObject.Properties[$name]) { $icons.$name } else { "" }
    '  {0}: {1}' -f ($name | ConvertTo-Json), ($value | ConvertTo-Json)
}
[IO.File]::WriteAllText($iconsPath, "{`r`n$($lines -join ",`r`n")`r`n}`r`n", [Text.UTF8Encoding]::new($false))
Write-Host "Stored a $size x $size icon for '$Key' ($($encoded.Length) base64 characters)."
