function Find-FeaturesByNameOrDescription {
    <#
        .SYNOPSIS
            Enhanced search function for Features panel that works with both original and responsive layouts.
            Searches through the Features on the Features Tab and hides all entries that do not match the search string.

        .PARAMETER SearchString
            The string to be searched for
        .PARAMETER TargetPanelName
            The name of the target panel to search within (defaults to "featurespanel")
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$SearchString = "",

        [Parameter(Mandatory=$false)]
        [string]$TargetPanelName = "featurespanel"
    )

    $targetPanel = $sync.Form.FindName($TargetPanelName)
    if (-not $targetPanel) {
        Write-Warning "Could not find panel: $TargetPanelName"
        return
    }

    # Reset the visibility if the search string is empty or the search is cleared
    if ([string]::IsNullOrWhiteSpace($SearchString)) {
        Show-AllFeaturesInPanel -TargetPanel $targetPanel
        return
    }

    # Determine layout type and search accordingly
    $isResponsiveLayout = Test-ResponsiveLayoutFeatures -TargetPanel $targetPanel

    if ($isResponsiveLayout) {
        Search-ResponsiveFeaturesLayout -TargetPanel $targetPanel -SearchString $SearchString
    } else {
        Search-OriginalFeaturesLayout -TargetPanel $targetPanel -SearchString $SearchString
    }
}

function Test-ResponsiveLayoutFeatures {
    param($TargetPanel)

    # Check if the first child is a ScrollViewer (responsive layout) or Border (original layout)
    if ($TargetPanel.Children.Count -gt 0) {
        return $TargetPanel.Children[0] -is [Windows.Controls.ScrollViewer]
    }
    return $false
}

function Show-AllFeaturesInPanel {
    param($TargetPanel)

    $isResponsiveLayout = Test-ResponsiveLayoutFeatures -TargetPanel $TargetPanel

    if ($isResponsiveLayout) {
        # Responsive layout: ScrollViewer -> StackPanel -> Category sections with WrapPanels
        $scrollViewer = $TargetPanel.Children[0]
        $mainContent = $scrollViewer.Content

        if ($mainContent -is [Windows.Controls.StackPanel]) {
            foreach ($categorySection in $mainContent.Children) {
                $categorySection.Visibility = [Windows.Visibility]::Visible

                # Find WrapPanel within category section
                foreach ($child in $categorySection.Children) {
                    $child.Visibility = [Windows.Visibility]::Visible

                    if ($child -is [Windows.Controls.WrapPanel]) {
                        foreach ($item in $child.Children) {
                            $item.Visibility = [Windows.Visibility]::Visible
                        }
                    }
                }
            }
        }
    } else {
        # Original layout: Show all categories and items
        $TargetPanel.Children | ForEach-Object {
            $_.Visibility = [Windows.Visibility]::Visible

            if ($_ -is [Windows.Controls.Border]) {
                $_.Visibility = [Windows.Visibility]::Visible

                $dockPanel = $_.Child
                if ($dockPanel -is [Windows.Controls.DockPanel]) {
                    $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] }
                    if ($itemsControl) {
                        foreach ($item in $itemsControl.Items) {
                            if ($item -is [Windows.Controls.Label]) {
                                $item.Visibility = [Windows.Visibility]::Visible
                            } elseif ($item -is [Windows.Controls.DockPanel] -or
                                      $item -is [Windows.Controls.StackPanel] -or
                                      $item -is [Windows.Controls.CheckBox] -or
                                      $item -is [Windows.Controls.Button]) {
                                $item.Visibility = [Windows.Visibility]::Visible
                            }
                        }
                    }
                }
            }
        }
    }
}

function Search-ResponsiveFeaturesLayout {
    param($TargetPanel, $SearchString)

    $scrollViewer = $TargetPanel.Children[0]
    $mainContent = $scrollViewer.Content

    if ($mainContent -is [Windows.Controls.StackPanel]) {
        foreach ($categorySection in $mainContent.Children) {
            if ($categorySection -is [Windows.Controls.StackPanel]) {
                $categoryVisible = $false
                $categoryHeader = $null
                $wrapPanel = $null

                # Find category header and wrap panel
                foreach ($child in $categorySection.Children) {
                    if ($child -is [Windows.Controls.Border] -and $child.Child -is [Windows.Controls.Label]) {
                        $categoryHeader = $child
                    } elseif ($child -is [Windows.Controls.WrapPanel]) {
                        $wrapPanel = $child
                    }
                }

                if ($wrapPanel) {
                    # Search through items in wrap panel
                    foreach ($itemContainer in $wrapPanel.Children) {
                        if ($itemContainer -is [Windows.Controls.Border]) {
                            $content = $itemContainer.Child
                            $matchFound = $false

                            # Search through the content for matching text
                            $matchFound = Search-FeatureElementContent -Element $content -SearchString $SearchString

                            if ($matchFound) {
                                $itemContainer.Visibility = [Windows.Visibility]::Visible
                                $categoryVisible = $true
                            } else {
                                $itemContainer.Visibility = [Windows.Visibility]::Collapsed
                            }
                        }
                    }
                }

                # Show/hide category section based on matches
                if ($categoryVisible) {
                    $categorySection.Visibility = [Windows.Visibility]::Visible
                    if ($categoryHeader) { $categoryHeader.Visibility = [Windows.Visibility]::Visible }
                } else {
                    $categorySection.Visibility = [Windows.Visibility]::Collapsed
                }
            }
        }
    }
}

function Search-OriginalFeaturesLayout {
    param($TargetPanel, $SearchString)

    $TargetPanel.Children | ForEach-Object {
        $categoryBorder = $_
        $categoryVisible = $false

        if ($_ -is [Windows.Controls.Border]) {
            $dockPanel = $_.Child
            if ($dockPanel -is [Windows.Controls.DockPanel]) {
                $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] }
                if ($itemsControl) {
                    $categoryLabel = $null

                    for ($i = 0; $i -lt $itemsControl.Items.Count; $i++) {
                        $item = $itemsControl.Items[$i]

                        if ($item -is [Windows.Controls.Label]) {
                            $categoryLabel = $item
                            $item.Visibility = [Windows.Visibility]::Collapsed
                        } else {
                            # Check various feature element types
                            $matchFound = Search-FeatureElementContent -Element $item -SearchString $SearchString

                            if ($matchFound) {
                                $item.Visibility = [Windows.Visibility]::Visible
                                if ($categoryLabel) { $categoryLabel.Visibility = [Windows.Visibility]::Visible }
                                $categoryVisible = $true
                            } else {
                                $item.Visibility = [Windows.Visibility]::Collapsed
                            }
                        }
                    }
                }
            }

            $categoryBorder.Visibility = if ($categoryVisible) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
        }
    }
}

function Search-FeatureElementContent {
    param($Element, $SearchString)

    if (-not $Element) { return $false }

    # Check different types of UI elements for matching content
    switch ($Element.GetType().Name) {
        "DockPanel" {
            foreach ($child in $Element.Children) {
                if (Search-FeatureElementContent -Element $child -SearchString $SearchString) {
                    return $true
                }
            }
        }
        "StackPanel" {
            foreach ($child in $Element.Children) {
                if (Search-FeatureElementContent -Element $child -SearchString $SearchString) {
                    return $true
                }
            }
        }
        "CheckBox" {
            if ($Element.Content -like "*$SearchString*" -or $Element.ToolTip -like "*$SearchString*") {
                return $true
            }
        }
        "Label" {
            if ($Element.Content -like "*$SearchString*" -or $Element.ToolTip -like "*$SearchString*") {
                return $true
            }
        }
        "Button" {
            if ($Element.Content -like "*$SearchString*" -or $Element.ToolTip -like "*$SearchString*") {
                return $true
            }
        }
        "ToggleButton" {
            if ($Element.Content -like "*$SearchString*" -or $Element.ToolTip -like "*$SearchString*") {
                return $true
            }
        }
        "ComboBox" {
            if ($Element.ToolTip -like "*$SearchString*") {
                return $true
            }
            # Check ComboBox items if needed
            foreach ($item in $Element.Items) {
                if ($item.Content -like "*$SearchString*") {
                    return $true
                }
            }
        }
        "RadioButton" {
            if ($Element.Content -like "*$SearchString*" -or $Element.ToolTip -like "*$SearchString*") {
                return $true
            }
        }
    }

    return $false
}
