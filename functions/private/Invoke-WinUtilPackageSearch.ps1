function Search-WinUtilPackages {
    <#
    .SYNOPSIS
        Searches winget and Chocolatey for packages matching a query.
    #>
    param([Parameter(Mandatory)][string]$Query)

    $results = [System.Collections.Generic.List[object]]::new()

    try {
        $lines = @(& winget search $Query --accept-source-agreements --disable-interactivity 2>$null)
        foreach ($line in $lines) {
            if ($line -match '^\s*-{3,}' -or $line -match '^\s*Name\s+Id') { continue }
            $parts = @($line -split '\s{2,}' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            if ($parts.Count -lt 2) { continue }
            $results.Add([pscustomobject]@{
                Source = "winget"
                Id = $parts[1].Trim()
                Name = $parts[0].Trim()
                Version = $(if ($parts.Count -ge 3) { $parts[2].Trim() } else { "" })
                IconUrl = $null
            })
        }
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "Guide" -Message "winget search failed: $($_.Exception.Message)"
    }

    try {
        $lines = @(& choco search $Query --page-size 10 --no-progress -r 2>$null)
        foreach ($line in ($lines | Select-Object -First 10)) {
            $parts = @($line -split '\|')
            if ($parts.Count -lt 1 -or [string]::IsNullOrWhiteSpace($parts[0])) { continue }
            $results.Add([pscustomobject]@{
                Source = "chocolatey"
                Id = $parts[0].Trim()
                Name = $parts[0].Trim()
                Version = $(if ($parts.Count -ge 2) { $parts[1].Trim() } else { "" })
                IconUrl = $null
            })
        }
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "Guide" -Message "Chocolatey search failed: $($_.Exception.Message)"
    }

    # Keep winget results ahead of Chocolatey results while removing duplicates
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $unique = [System.Collections.Generic.List[object]]::new()
    foreach ($item in $results) {
        $identity = "$($item.Source)|$($item.Id)"
        if ($seen.Add($identity)) { $unique.Add($item) }
        if ($unique.Count -ge 20) { break }
    }
    foreach ($item in $unique) {
        $item.IconUrl = Get-WinUtilPackageIconUrl -Package $item
    }
    return $unique
}

function Get-WinUtilPackageIconUrl {
    <#
    .SYNOPSIS
        Resolves a package icon URL from Chocolatey or winget metadata.
    #>
    param([Parameter(Mandatory)][psobject]$Package)

    if ($Package.Source -eq "chocolatey") {
        try {
            $uri = "https://community.chocolatey.org/api/v2/Packages?`$filter=Id%20eq%20%27$([uri]::EscapeDataString([string]$Package.Id))%27&`$select=Id,IconUrl"
            [xml]$feed = (Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 8).Content
            $ns = New-Object System.Xml.XmlNamespaceManager($feed.NameTable)
            $ns.AddNamespace("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata")
            $ns.AddNamespace("d", "http://schemas.microsoft.com/ado/2007/08/dataservices")
            $properties = $feed.SelectSingleNode("//m:properties", $ns)
            if ($null -ne $properties) {
                $node = $properties.SelectSingleNode("d:IconUrl", $ns)
                if ($null -ne $node -and $node.InnerText -notmatch '\.svg($|\?)') { return $node.InnerText }
            }
        } catch { }
    } else {
        try {
            $uri = "https://api.winget.run/v2/packages/$([uri]::EscapeDataString([string]$Package.Id))"
            $data = Invoke-RestMethod -Uri $uri -TimeoutSec 8
            foreach ($entry in @($data.Packages)) {
                if ($entry.Id -ieq [string]$Package.Id -and -not [string]::IsNullOrWhiteSpace([string]$entry.IconUrl) -and $entry.IconUrl -notmatch '\.svg($|\?)') {
                    return [string]$entry.IconUrl
                }
            }
        } catch { }
    }
    return $null
}

function Show-WinUtilPackageResults {
    <#
    .SYNOPSIS
        Renders dynamic package results as selectable cards on the interface thread.
    #>
    param([object[]]$Results)

    $panel = $sync.WPFGuidePackageList
    if ($null -eq $panel) { return }
    $panel.Children.Clear()
    $sync.WPFGuidePackageResults.Visibility = "Visible"
    $sync.WPFGuideSearchStatus.Text = "$($Results.Count) package(s) found"

    foreach ($item in @($Results)) {
        $check = New-Object System.Windows.Controls.CheckBox
        try { $check.Style = $sync.Form.TryFindResource("GuideCircularCheckBox") } catch { }
        $check.Tag = $item
        $check.Margin = [System.Windows.Thickness]::new(4)
        $check.MinWidth = 220

        $stack = New-Object System.Windows.Controls.StackPanel
        $stack.Orientation = "Horizontal"
        $stack.VerticalAlignment = "Center"

        $image = New-Object System.Windows.Controls.Image
        $image.Width = 24
        $image.Height = 24
        $image.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        if (-not [string]::IsNullOrWhiteSpace([string]$item.IconUrl)) {
            try {
                $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
                $bitmap.BeginInit()
                $bitmap.UriSource = [uri]$item.IconUrl
                $bitmap.EndInit()
                $image.Source = $bitmap
            } catch { }
        }

        $label = New-Object System.Windows.Controls.TextBlock
        $label.Text = "$($item.Name)  [$($item.Source)]"
        $label.Foreground = Get-WinUtilGuideBrush -Name "MainForegroundColor"
        $label.VerticalAlignment = "Center"
        $label.TextWrapping = "NoWrap"

        $stack.Children.Add($image) | Out-Null
        $stack.Children.Add($label) | Out-Null
        $check.Content = $stack

        $check.Add_Checked({
            $selected = $this.Tag
            $exists = @($sync.GuideDynamicPackages | Where-Object { $_.Id -eq $selected.Id -and $_.Source -eq $selected.Source }).Count -gt 0
            if (-not $exists) { $sync.GuideDynamicPackages.Add($selected) }
        })
        $check.Add_Unchecked({
            $removed = $this.Tag
            $match = @($sync.GuideDynamicPackages | Where-Object { $_.Id -eq $removed.Id -and $_.Source -eq $removed.Source })[0]
            if ($null -ne $match) { $null = $sync.GuideDynamicPackages.Remove($match) }
        })

        $panel.Children.Add($check) | Out-Null
    }
}

function Invoke-WinUtilPackageSearch {
    <#
    .SYNOPSIS
        Starts a background search and renders its results when they arrive.
    #>
    param([string]$Query)

    if ([string]::IsNullOrWhiteSpace($Query)) {
        $sync.WPFGuideSearchStatus.Text = "Type an app name in the search box first"
        return
    }

    $sync.WPFGuidePackageList.Children.Clear()
    $sync.WPFGuidePackageResults.Visibility = "Collapsed"
    $sync.WPFGuideSearchStatus.Text = "Searching package managers..."

    Start-WinUtilJob -Name "Package search" -Description "Searching winget and Chocolatey" -QueueIfBusy -Parameters @{ Query = $Query } -ScriptBlock {
        param($Query)
        $found = Search-WinUtilPackages -Query $Query
        Invoke-WPFUIThread -Parameters @{ Results = $found } -ScriptBlock {
            param($Results)
            Show-WinUtilPackageResults -Results $Results
        }
    }
}

function Invoke-WinUtilGuideDynamicInstall {
    <#
    .SYNOPSIS
        Installs packages picked from the dynamic search results.
    #>
    param([Parameter(Mandatory)][object[]]$Packages)

    Start-WinUtilJob -Name "Dynamic install" -Description "Installing searched packages" -QueueIfBusy -Parameters @{ Packages = $Packages } -ScriptBlock {
        param($Packages)
        $total = @($Packages).Count
        $completed = 0
        foreach ($package in $Packages) {
            $completed++
            Step-WinUtilJob -Status "Installing $($package.Name) ($completed/$total)" -Percent ([int]((($completed - 1) / $total) * 100))
            if ($package.Source -eq "chocolatey") {
                & choco install $package.Id -y --no-progress
            } else {
                & winget install --id $package.Id --accept-package-agreements --accept-source-agreements --silent
            }
            Step-WinUtilJob -Status "Installed $($package.Name) ($completed/$total)" -Percent ([int](($completed / $total) * 100))
        }
    }
}
