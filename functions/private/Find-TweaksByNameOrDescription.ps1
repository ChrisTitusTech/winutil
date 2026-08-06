function Find-TweaksByNameOrDescription {
    <#
    .SYNOPSIS
        Filters tweak/appx entries by name or description using literal string matching.
    .PARAMETER SearchString
        The string to search for. Treated as a literal (no wildcard expansion).
    #>
    param(
        [string]$SearchString = ""
    )

    # $sync is always in scope in the compiled script - no multi-level fallback needed
    if ($null -eq $sync -or $null -eq $sync.Form) { return }

    $panelName = if ($sync.currentTab -eq "AppX") { "appxpanel" } else { "tweakspanel" }
    try { $tweaksPanel = $sync.Form.FindName($panelName) } catch { return }
    if ($null -eq $tweaksPanel) { return }

    # --- Helper: extract searchable text from a DockPanel or StackPanel item ---
    function Get-ItemSearchText($item) {
        $text = ""; $tip = ""
        if ($item -is [Windows.Controls.DockPanel]) {
            $label = $item.Children | Where-Object { $_ -is [Windows.Controls.Label] } | Select-Object -First 1
            if ($label) { $text = [string]$label.Content; $tip = [string]$label.ToolTip }
        } elseif ($item -is [Windows.Controls.StackPanel]) {
            $cb = $item.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] } | Select-Object -First 1
            if ($cb) { $text = [string]$cb.Content; $tip = [string]$cb.ToolTip }
        }
        return @{ Text = $text; Tip = $tip }
    }

    try {
        # Reset visibility when search is cleared
        if ([string]::IsNullOrWhiteSpace($SearchString)) {
            foreach ($categoryBorder in $tweaksPanel.Children) {
                if ($null -eq $categoryBorder) { continue }
                $categoryBorder.Visibility = [Windows.Visibility]::Visible
                if ($categoryBorder -is [Windows.Controls.Border] -and $categoryBorder.Child -is [Windows.Controls.DockPanel]) {
                    $ic = $categoryBorder.Child.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] } | Select-Object -First 1
                    if ($ic) {
                        foreach ($item in $ic.Items) {
                            if ($null -eq $item) { continue }
                            if ($item -is [Windows.Controls.Label]) {
                                $item.Visibility = [Windows.Visibility]::Visible
                                # Respect collapsed state: labels starting with "+" keep items collapsed
                                $labelStr = [string]$item.Content
                                if ($labelStr.StartsWith("+ ")) {
                                    $collapsed = $true
                                } else {
                                    $collapsed = $false
                                }
                            } else {
                                $item.Visibility = if ($collapsed) { [Windows.Visibility]::Collapsed } else { [Windows.Visibility]::Visible }
                            }
                        }
                    }
                }
            }
            return
        }

        # Perform literal search
        foreach ($categoryBorder in $tweaksPanel.Children) {
            $categoryHasMatch = $false
            if (-not ($categoryBorder -is [Windows.Controls.Border])) { continue }
            if (-not ($categoryBorder.Child -is [Windows.Controls.DockPanel])) { continue }

            $ic = $categoryBorder.Child.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] } | Select-Object -First 1
            if ($null -eq $ic) { continue }

            $categoryLabel = $null
            for ($i = 0; $i -lt $ic.Items.Count; $i++) {
                $item = $ic.Items[$i]
                if ($null -eq $item) { continue }

                if ($item -is [Windows.Controls.Label]) {
                    $categoryLabel = $item
                    $item.Visibility = [Windows.Visibility]::Collapsed
                    continue
                }

                # Unified search for both DockPanel and StackPanel items
                if ($item -is [Windows.Controls.DockPanel] -or $item -is [Windows.Controls.StackPanel]) {
                    $search = Get-ItemSearchText $item
                    $isMatch = ($search.Text -and $search.Text.IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) -or
                               ($search.Tip -and $search.Tip.IndexOf($SearchString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)

                    if ($isMatch) {
                        $item.Visibility = [Windows.Visibility]::Visible
                        $categoryHasMatch = $true
                    } else {
                        $item.Visibility = [Windows.Visibility]::Collapsed
                    }
                }
            }

            # Update category label and border visibility
            if ($categoryHasMatch -and $null -ne $categoryLabel) {
                $categoryLabel.Visibility = [Windows.Visibility]::Visible
                $labelStr = [string]$categoryLabel.Content
                if ($labelStr.StartsWith("+ ")) {
                    $categoryLabel.Content = "- " + $labelStr.Substring(2)
                }
            }
            $categoryBorder.Visibility = if ($categoryHasMatch) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
        }
    } catch {
        # Log instead of silently swallowing - but only at DEBUG to avoid keystroke spam
        Write-WinUtilLog -Level "DEBUG" -Component "Search" -Message "Tweaks search error: $($_.Exception.Message)"
    }
}
