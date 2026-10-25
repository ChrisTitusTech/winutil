<#
    .SYNOPSIS
        Adds or replaces an app's icon in config/icons

    .DESCRIPTION
        Scales an image (PNG, ICO, JPG, GIF or BMP) to fit a 48x48 transparent canvas and saves it
        as config/icons/<Key>.png, where Key is the app's key in config/applications.json. The file
        is embedded in the script when it is compiled. An app without an icon file falls back to
        its website's favicon.

    .EXAMPLE
        .\tools\New-WinUtilIcon.ps1 -Key brave -Path C:\Downloads\brave.png
#>
param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Path
)

Add-Type -AssemblyName System.Drawing

$size = 48
$margin = 0.04
$configRoot = Join-Path $PSScriptRoot "..\config"
$applications = Get-Content (Join-Path $configRoot "applications.json") -Raw | ConvertFrom-Json
if (-not $applications.PSObject.Properties[$Key]) { throw "'$Key' is not a key in config/applications.json." }

# Read the file into memory, so an existing icon can be given as its own input without being locked
$sourceStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes((Resolve-Path $Path)))
$source = [Drawing.Image]::FromStream($sourceStream)
$canvas = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = $null
try {
    $graphics = [Drawing.Graphics]::FromImage($canvas)
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $fit = $size * (1 - 2 * $margin) / [Math]::Max($source.Width, $source.Height)
    $width = [int][Math]::Round($source.Width * $fit)
    $height = [int][Math]::Round($source.Height * $fit)
    $graphics.DrawImage($source, [int](($size - $width) / 2), [int](($size - $height) / 2), $width, $height)

    $iconsFolder = Join-Path $configRoot "icons"
    $null = New-Item -ItemType Directory -Path $iconsFolder -Force
    $target = Join-Path (Resolve-Path $iconsFolder) "$Key.png"
    $canvas.Save($target, [Drawing.Imaging.ImageFormat]::Png)
} finally {
    if ($graphics) { $graphics.Dispose() }
    $source.Dispose(); $sourceStream.Dispose(); $canvas.Dispose()
}

Write-Host "Saved a $size x $size icon for '$Key' ($((Get-Item $target).Length) bytes) to config/icons/$Key.png."
