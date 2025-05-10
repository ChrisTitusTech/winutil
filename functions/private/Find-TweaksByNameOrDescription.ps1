function Find-TweaksByNameOrDescription {
    <#
        .SYNOPSIS
            Searches through the Tweaks on the Tweaks Tab and hides all entries that do not match the search string

        .PARAMETER SearchString
            The string to be searched for
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$SearchString = ""
    )

    # Reset the visibility if the search string is empty or the search is cleared
    if ([string]::IsNullOrWhiteSpace($SearchString)) {
        # Show all categories
        $tweakspanel = $sync.Form.FindName("tweakspanel")
        $tweakspanel.Children | ForEach-Object {
            $_.Visibility = [Windows.Visibility]::Visible

            # Foreach category section, show all items
            if ($_ -is [Windows.Controls.Border]) {
                $_.Visibility = [Windows.Visibility]::Visible

                # Find ItemsControl
                $dockPanel = $_.Child
                if ($dockPanel -is [Windows.Controls.DockPanel]) {
                    $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] }
                    if ($itemsControl) {
                        # Show items in the category
                        foreach ($item in $itemsControl.Items) {
                            if ($item -is [Windows.Controls.Label]) {
                                $item.Visibility = [Windows.Visibility]::Visible
                            } elseif ($item -is [Windows.Controls.DockPanel] -or
                                      $item -is [Windows.Controls.StackPanel]) {
                                $item.Visibility = [Windows.Visibility]::Visible
                            }
                        }
                    }
                }
            }
        }
        return
    }

    # Search for matching tweaks when search string is not null
    $tweakspanel = $sync.Form.FindName("tweakspanel")

    $tweakspanel.Children | ForEach-Object {
        $categoryBorder = $_
        $categoryVisible = $false

        if ($_ -is [Windows.Controls.Border]) {
            # Find the ItemsControl
            $dockPanel = $_.Child
            if ($dockPanel -is [Windows.Controls.DockPanel]) {
                $itemsControl = $dockPanel.Children | Where-Object { $_ -is [Windows.Controls.ItemsControl] }
                if ($itemsControl) {
                    $categoryLabel = $null

                    # Process all items in the ItemsControl
                    for ($i = 0; $i -lt $itemsControl.Items.Count; $i++) {
                        $item = $itemsControl.Items[$i]

                        if ($item -is [Windows.Controls.Label]) {
                            $categoryLabel = $item
                            $item.Visibility = [Windows.Visibility]::Collapsed
                        } elseif ($item -is [Windows.Controls.DockPanel]) {
                            $checkbox = $item.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] } | Select-Object -First 1
                            $label = $item.Children | Where-Object { $_ -is [Windows.Controls.Label] } | Select-Object -First 1

                            if ($label -and ($label.Content -like "*$SearchString*" -or $label.ToolTip -like "*$SearchString*")) {
                                $item.Visibility = [Windows.Visibility]::Visible
                                if ($categoryLabel) { $categoryLabel.Visibility = [Windows.Visibility]::Visible }
                                $categoryVisible = $true
                            } else {
                                $item.Visibility = [Windows.Visibility]::Collapsed
                            }
                        } elseif ($item -is [Windows.Controls.StackPanel]) {
                            # StackPanel which contain checkboxes or other elements
                            $checkbox = $item.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] } | Select-Object -First 1

                            if ($checkbox -and ($checkbox.Content -like "*$SearchString*" -or $checkbox.ToolTip -like "*$SearchString*")) {
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

            # Set the visibility based on if any item matched
            $categoryBorder.Visibility = if ($categoryVisible) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }

        }
    }
}
