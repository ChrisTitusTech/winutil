function Initialize-WinUtilLanguageMenu {
    <#
        .SYNOPSIS
            Builds the language selectors from config/languages.json.

        .DESCRIPTION
            Each entry in $sync.configs.languages becomes a selectable control whose label comes
            from the locale key named by displayNameKey. By default it fills the old settings
            popup menu (LanguageMenuItems); when -ContainerName is given it fills that named
            panel with Buttons instead, used by the unified settings page. Adding a language only
            needs a locale file and a languages.json entry.
    #>
    param(
        [string]$ContainerName
    )

    $hostPanel = $null
    $asButtons = $false
    if ($ContainerName) {
        if ($null -ne $sync -and $sync.ContainsKey($ContainerName)) { $hostPanel = $sync[$ContainerName] }
        $asButtons = $true
    } else {
        $hostPanel = $sync.LanguageMenuItems
    }
    if ($null -eq $hostPanel) { return }

    $languages = $null
    if ($null -ne $sync.configs) {
        $configs = $sync.configs
        if ($configs -is [System.Collections.IDictionary]) { $languages = $configs["languages"] } else { $languages = $configs.languages }
    }
    if ($null -eq $languages) { return }

    foreach ($entry in $languages.PSObject.Properties) {
        $code = $entry.Name
        $info = $entry.Value
        $displayKey = if ($info -is [System.Collections.IDictionary]) { $info["displayNameKey"] } else { $info.displayNameKey }
        if ([string]::IsNullOrWhiteSpace([string]$displayKey)) { $displayKey = "s_language_$code" }

        if ($asButtons) {
            $item = New-Object Windows.Controls.Button
            $item.Height = 26
            $item.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
            $item.SetResourceReference([Windows.Controls.Button]::ContentProperty, $displayKey)
        } else {
            $item = New-Object Windows.Controls.MenuItem
            $fontSize = $null
            $foreground = $null
            if ($null -ne $sync.Form) {
                try { $fontSize = $sync.Form.TryFindResource("ButtonFontSize") } catch { }
                try { $foreground = $sync.Form.TryFindResource("MainForegroundColor") } catch { }
            }
            if ($null -ne $fontSize) { $item.FontSize = [double]$fontSize }
            if ($null -ne $foreground) { $item.Foreground = $foreground }
            $item.SetResourceReference([Windows.Controls.MenuItem]::HeaderProperty, $displayKey)
        }

        $item.Name = "LanguageMenuItem_$($code -replace '[^A-Za-z0-9_]', '_')"
        $item.Tag = [string]$code
        $item.Add_Click({
            # Read the code from the clicked item's Tag: a captured loop variable would be
            # empty or stale by the time the handler actually runs on the UI thread.
            $selected = [string]$this.Tag
            if (-not [string]::IsNullOrWhiteSpace($selected)) {
                Set-WinUtilLanguage -Language $selected
            }
        })
        [void]$hostPanel.Children.Add($item)
    }
}
