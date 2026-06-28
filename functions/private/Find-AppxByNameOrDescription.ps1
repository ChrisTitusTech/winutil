function Find-AppxByNameOrDescription {
    <#
        .SYNOPSIS
            Searches through the AppX packages on the AppX Tab and hides all entries that do not match the search string

        .PARAMETER SearchString
            The string to be searched for. Wildcards are treated as literal characters.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SearchString = ""
    )

    if ($null -eq $Sync) {
        $Sync = $global:sync
        if ($null -eq $Sync) {
            $Sync = $script:sync
        }
    }

    if ($null -eq $Sync) {
        return
    }

    if ($null -eq $Sync.Form) {
        return
    }

    $appxPanel = $null
    try {
        $appxPanel = $Sync.Form.FindName("appxpanel")
    }
    catch {
        return
    }

    if ($null -eq $appxPanel) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($SearchString)) {
        try {
            $appxPanel.Children | ForEach-Object {
                $categoryBorder = $_
                if ($null -ne $categoryBorder) {
                    $categoryBorder.Visibility = [Windows.Visibility]::Visible
                }

                if ($categoryBorder -is [Windows.Controls.Border]) {
                    $dockPanel = $categoryBorder.Child
                    if ($dockPanel -is [Windows.Controls.DockPanel]) {
                        $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] } | Select-Object -First 1
                        if ($null -ne $itemsControl) {
                            foreach ($item in $itemsControl.Items) {
                                if ($null -ne $item) {
                                    $item.Visibility = [Windows.Visibility]::Visible
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {}
        return
    }

    try {
        $searchTerm = $SearchString
        if ($null -eq $searchTerm) {
            $searchTerm = ""
        }

        $appxPanel.Children | ForEach-Object {
            $categoryBorder = $_
            $categoryHasMatch = $false

            if ($categoryBorder -is [Windows.Controls.Border]) {
                $dockPanel = $categoryBorder.Child
                if ($dockPanel -is [Windows.Controls.DockPanel]) {
                    $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] } | Select-Object -First 1
                    if ($null -ne $itemsControl) {
                        $categoryLabel = $null

                        for ($i = 0; $i -lt $itemsControl.Items.Count; $i++) {
                            $item = $itemsControl.Items[$i]
                            if ($null -eq $item) {
                                continue
                            }

                            if ($item -is [Windows.Controls.Label]) {
                                $categoryLabel = $item
                                $item.Visibility = [Windows.Visibility]::Collapsed
                            }
                            elseif ($item -is [Windows.Controls.StackPanel]) {
                                $checkbox = $item.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] } | Select-Object -First 1
                                $itemMatches = $false

                                if ($null -ne $checkbox) {
                                    $checkboxContent = $checkbox.Content
                                    $checkboxToolTip = $checkbox.ToolTip

                                    if ($null -eq $checkboxContent) { $checkboxContent = "" }
                                    if ($null -eq $checkboxToolTip) { $checkboxToolTip = "" }

                                    $checkboxContentStr = [string]$checkboxContent
                                    $checkboxToolTipStr = [string]$checkboxToolTip

                                    $contentMatch = $checkboxContentStr.IndexOf($searchTerm, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
                                    $toolTipMatch = $checkboxToolTipStr.IndexOf($searchTerm, [System.StringComparison]::OrdinalIgnoreCase) -ge 0

                                    if ($contentMatch -or $toolTipMatch) {
                                        $itemMatches = $true
                                    }
                                }

                                if ($itemMatches) {
                                    $item.Visibility = [Windows.Visibility]::Visible
                                    $categoryHasMatch = $true
                                }
                                else {
                                    $item.Visibility = [Windows.Visibility]::Collapsed
                                }
                            }
                        }

                        if ($categoryHasMatch) {
                            if ($null -ne $categoryLabel) {
                                $categoryLabel.Visibility = [Windows.Visibility]::Visible

                                $labelContent = $categoryLabel.Content
                                if ($null -ne $labelContent) {
                                    $labelStr = [string]$labelContent
                                    if ($labelStr.StartsWith("+ ")) {
                                        $categoryLabel.Content = "- " + $labelStr.Substring(2)
                                    }
                                }
                            }
                        }
                    }
                }

                if ($categoryHasMatch) {
                    $categoryBorder.Visibility = [Windows.Visibility]::Visible
                }
                else {
                    $categoryBorder.Visibility = [Windows.Visibility]::Collapsed
                }
            }
        }
    }
    catch {}
}
