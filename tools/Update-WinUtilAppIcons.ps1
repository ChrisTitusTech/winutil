<#
    .SYNOPSIS
        Fills in missing application icons from package-manager metadata or a favicon service.

    .DESCRIPTION
        For every application in config/applications.json without config/icons/<key>.png, the tool
        tries, in order: the Chocolatey package IconUrl, the winget package IconUrl, then Google's
        favicon service using the application link. SVG icons are skipped because WPF cannot draw
        them; the next source is used instead. Each downloaded image is scaled onto a 48x48
        transparent canvas and saved as a PNG under config/icons, where Compile.ps1 embeds it.

        The tool is idempotent: applications that already have an icon are left untouched.
    #>
    param(
        # Only process these keys. When omitted, every application without an icon is processed.
        [string[]]$Key,

        # Report what would be done without writing any files.
        [switch]$WhatIf,

        # Manual icon URLs for keys whose automatic sources have no usable image.
        [hashtable]$IconUrlOverride = @{}
    )

    $ErrorActionPreference = "Stop"
    Add-Type -AssemblyName System.Drawing

    $configRoot = Join-Path $PSScriptRoot "..\config"
    $iconsRoot = Join-Path $configRoot "icons"
    $applications = Get-Content (Join-Path $configRoot "applications.json") -Raw | ConvertFrom-Json
    $null = New-Item -ItemType Directory -Path $iconsRoot -Force

    function Get-ChocolateyIconUrl {
        param([string]$PackageId)

        if ([string]::IsNullOrWhiteSpace($PackageId) -or $PackageId -eq "na") { return $null }
        try {
            $uri = "https://community.chocolatey.org/api/v2/Packages?`$filter=Id%20eq%20%27$([uri]::EscapeDataString($PackageId))%27&`$select=Id,IconUrl"
            $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 20
            [xml]$feed = $response.Content
            $ns = New-Object System.Xml.XmlNamespaceManager($feed.NameTable)
            $ns.AddNamespace("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata")
            $ns.AddNamespace("d", "http://schemas.microsoft.com/ado/2007/08/dataservices")
            $properties = $feed.SelectSingleNode("//m:properties", $ns)
            if ($null -eq $properties) { return $null }
            $node = $properties.SelectSingleNode("d:IconUrl", $ns)
            if ($null -eq $node) { return $null }
            return $node.InnerText
        } catch {
            return $null
        }
    }

    function Get-WingetIconUrl {
        param([string]$PackageId)

        if ([string]::IsNullOrWhiteSpace($PackageId)) { return $null }
        try {
            $uri = "https://api.winget.run/v2/packages/$([uri]::EscapeDataString($PackageId))"
            $result = Invoke-RestMethod -Uri $uri -TimeoutSec 20
            foreach ($package in @($result.Packages)) {
                if ($package.Id -ieq $PackageId -and -not [string]::IsNullOrWhiteSpace([string]$package.IconUrl)) {
                    return [string]$package.IconUrl
                }
            }
        } catch { }
        return $null
    }

    function Get-FaviconUrl {
        param([string]$Link)

        if ([string]::IsNullOrWhiteSpace($Link)) { return $null }
        return "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($Link))"
    }

    function Save-IconFromUrl {
        param(
            [string]$Url,
            [string]$Destination
        )

        if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
        # WPF cannot render SVG, and System.Drawing cannot decode it either.
        if ($Url -match '\.svg($|\?)') { return $false }

        $stream = $null
        $source = $null
        $canvas = $null
        $graphics = $null
        try {
            $bytes = (Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 25).Content
            $stream = [IO.MemoryStream]::new($bytes)
            $source = [Drawing.Image]::FromStream($stream)
            $canvas = [Drawing.Bitmap]::new(48, 48, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [Drawing.Graphics]::FromImage($canvas)
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            $margin = 0.04
            $fit = 48 * (1 - 2 * $margin) / [Math]::Max($source.Width, $source.Height)
            $width = [int][Math]::Round($source.Width * $fit)
            $height = [int][Math]::Round($source.Height * $fit)
            $graphics.DrawImage($source, [int]((48 - $width) / 2), [int]((48 - $height) / 2), $width, $height)
            $canvas.Save($Destination, [Drawing.Imaging.ImageFormat]::Png)

            if ((Get-Item -LiteralPath $Destination).Length -gt 8KB) {
                Remove-Item -LiteralPath $Destination -Force
                return $false
            }
            return $true
        } catch {
            if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Force }
            return $false
        } finally {
            if ($null -ne $graphics) { $graphics.Dispose() }
            if ($null -ne $source) { $source.Dispose() }
            if ($null -ne $canvas) { $canvas.Dispose() }
            if ($null -ne $stream) { $stream.Dispose() }
        }
    }

    $entries = @($applications.PSObject.Properties)
    if ($Key) { $entries = @($entries | Where-Object { $Key -contains $_.Name }) }

    $added = 0
    $skipped = 0
    $failed = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $entries) {
        $appKey = $entry.Name
        $destination = Join-Path $iconsRoot "$appKey.png"
        if (Test-Path -LiteralPath $destination) {
            $skipped++
            continue
        }

        $value = $entry.Value
        $duckDuckGoUrl = $null
        try {
            $hostName = ([uri]$value.link).Host
            $duckDuckGoUrl = "https://icons.duckduckgo.com/ip3/$hostName.ico"
        } catch { }

        $urls = @(
            $(if ($IconUrlOverride.ContainsKey($appKey)) { $IconUrlOverride[$appKey] } else { $null }),
            (Get-ChocolateyIconUrl -PackageId $value.choco),
            (Get-WingetIconUrl -PackageId $value.winget),
            (Get-FaviconUrl -Link $value.link),
            $duckDuckGoUrl
        )

        $saved = $false
        foreach ($url in $urls) {
            if ([string]::IsNullOrWhiteSpace($url)) { continue }
            if ($WhatIf) {
                Write-Host "Would fetch $appKey from $url"
                $saved = $true
                break
            }
            if (Save-IconFromUrl -Url $url -Destination $destination) {
                Write-Host "Saved $appKey from $url"
                $saved = $true
                $added++
                break
            }
        }
        if (-not $saved -and -not $WhatIf) { $failed.Add($appKey) }
    }

    Write-Host "Icons added: $added, already present: $skipped, failed: $($failed.Count)."
    if ($failed.Count -gt 0) {
        Write-Host "Failed keys: $($failed -join ', ')"
    }
