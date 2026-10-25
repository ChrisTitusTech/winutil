function Initialize-InstallAppEntries {
    <#
        .SYNOPSIS
            Creates the app entries for a set of apps and places them on the install tab
            Used as part of the Install Tab UI generation

        .DESCRIPTION
            The entries are written out as one XAML document and parsed in a single call. Building
            a card control by control costs several PowerShell calls per element, which is most of
            the time the Install tab takes to appear; the parser does the same work natively.

            Styles and colours are DynamicResource references, so they resolve against the window
            once the entries are attached and follow theme changes. Mouse and check handling is not
            attached per entry: the category panel holds one set of handlers for all its cards (see
            Get-WinUtilAppEntryHandlers).

        .PARAMETER TargetElement
            The WrapPanel into which the entries should be placed

        .PARAMETER AppKeys
            The keys of the apps inside the $sync.configs.applicationsHashtable

        .OUTPUTS
            The check box of each entry, in the order of AppKeys
    #>
    param(
        [Windows.Controls.WrapPanel]$TargetElement,
        [string[]]$AppKeys
    )

    $document = [System.Text.StringBuilder]::new()
    [void]$document.Append('<WrapPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">')

    $icons = @{}
    foreach ($appKey in $AppKeys) {
        $app = $sync.configs.applicationsHashtable[$appKey]
        $icon = Get-WinUtilAppIcon -Key ($appKey -replace '^WPFInstall', '')
        $icons[$appKey] = $icon

        $name = [Security.SecurityElement]::Escape($app.content)
        $key = [Security.SecurityElement]::Escape($appKey)
        # Sanitize the name for WPF
        $id = $appKey.Replace('-', '_')
        $tooltip = [Security.SecurityElement]::Escape((Get-WinUtilEntryToolTip -Description $app.description -Key $appKey)).Replace("`r", '').Replace("`n", '&#10;')
        $letter = [Security.SecurityElement]::Escape($app.content.TrimStart(".").Substring(0, 1).ToUpper())

        # A bundled icon sits on a plate that follows the theme, because logos are drawn for light
        # backgrounds. An app deliberately listed without one keeps a bare letter tile.
        $plate = if ($icon -eq $false) { ' Background="{x:Null}"' } else { '' }
        $letterVisibility = if ($icon) { ' Visibility="Collapsed"' } else { '' }

        [void]$document.Append(@"
<Border Style="{DynamicResource AppEntryBorderStyle}" Tag="$key" ToolTip="$tooltip" AutomationProperties.Name="$name"><Grid><CheckBox x:Name="$id" Tag="$key" Style="{DynamicResource AppEntryCheckboxStyle}" AutomationProperties.Name="$name"><StackPanel Orientation="Horizontal" VerticalAlignment="Center"><Border Style="{DynamicResource AppEntryIconPlateStyle}"$plate><Grid><TextBlock Style="{DynamicResource AppEntryIconLetterStyle}" Text="$letter"$letterVisibility/><Image x:Name="Icon_$id" Style="{DynamicResource AppEntryIconStyle}"/></Grid></Border><TextBlock Style="{DynamicResource AppEntryNameStyle}" Text="$name"/></StackPanel></CheckBox>
"@)

        # Marks FOSS apps with a corner badge, bled into the border padding so it sits on the edge.
        # The same artwork as New-WinUtilFossBadge, written out so it is parsed with the rest.
        if ($app.foss -eq $true) {
            [void]$document.Append('<Viewbox Width="24" Height="24" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,-4,-6,0" ToolTip="Free and Open Source Software"><Grid Width="22" Height="22"><Path Fill="#138F53" Data="M 0,0 L 17,0 A 5,5 0 0 1 22,5 L 22,22 Z"/><Path Stroke="#F7F7F7" StrokeThickness="2.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Data="M 13.61,9.225 A 3.4,3.4 0 1 1 17.51,9.225"/></Grid></Viewbox>')
        }
        [void]$document.Append('</Grid></Border>')
    }
    [void]$document.Append('</WrapPanel>')

    $parsed = [Windows.Markup.XamlReader]::Parse($document.ToString())
    $handlers = Get-WinUtilAppEntryHandlers

    $checkBoxes = foreach ($appKey in $AppKeys) {
        $id = $appKey.Replace('-', '_')
        $checkBox = $parsed.FindName($id)
        $icon = $icons[$appKey]

        if ($icon) {
            $parsed.FindName("Icon_$id").Source = $icon
        } elseif ($null -eq $icon -and $sync.configs.applicationsHashtable[$appKey].link) {
            # No bundled icon: ask the favicon service, as before
            $logo = $parsed.FindName("Icon_$id")
            $checkBox.Content.Children[0].Child.Children[0].Visibility = "Collapsed"
            $logo.Add_ImageFailed($handlers.ImageFailed)
            try {
                # Avoid reusing a cached WIC image from an earlier window in this process.
                # Keep downloading in WPF so icons do not occupy the shared job pool.
                $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
                $bitmap.BeginInit()
                $bitmap.CreateOptions = [Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache
                $bitmap.UriCachePolicy = [Net.Cache.RequestCachePolicy]::new([Net.Cache.RequestCacheLevel]::BypassCache)
                $bitmap.UriSource = [uri]"https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($sync.configs.applicationsHashtable[$appKey].link))"
                $bitmap.EndInit()
                $logo.Source = $bitmap
            } catch {
                $logo.Visibility = "Collapsed"
                $checkBox.Content.Children[0].Child.Children[0].Visibility = "Visible"
            }
        }
        $checkBox
    }

    # Move the cards across in one go. Taking them out first keeps each from having two parents.
    $entries = @($parsed.Children)
    $parsed.Children.Clear()
    foreach ($entry in $entries) {
        [void]$TargetElement.Children.Add($entry)
    }

    # Attached last, so that checking an app that was already chosen updates its card
    foreach ($checkBox in $checkBoxes) {
        if ($sync.selectedApps -contains $checkBox.Tag) {
            $checkBox.IsChecked = $true
        }
    }

    return $checkBoxes
}
