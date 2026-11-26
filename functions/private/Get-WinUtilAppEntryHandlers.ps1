function Get-WinUtilAppEntryHandlers {
    <#
        .SYNOPSIS
            The event handlers shared by every app entry on the Install tab

        .DESCRIPTION
            Building handlers per entry is a large part of the cost of drawing the app list, and
            none of them needs to be per entry. Clicks and check changes bubble, so each category
            panel carries one set (see Initialize-InstallCategoryAppList) that finds the entry
            the event came from. Hover is a trigger in AppEntryBorderStyle.

            The handlers are made once and reused, and they read everything from the event, so a
            single instance serves every app.
    #>

    if ($null -ne $script:WinUtilAppEntryHandlers) {
        return $script:WinUtilAppEntryHandlers
    }

    $script:WinUtilAppEntryHandlers = @{
        BorderClick = [Windows.Input.MouseButtonEventHandler]{
            param($sender, $e)
            $entry = Get-WinUtilAppEntryFromElement -Element $e.OriginalSource
            if ($entry) {
                $childCheckbox = $sync.$($entry.Tag)
                $childCheckbox.IsChecked = -not $childCheckbox.IsChecked
            }
        }
        RightClick = [Windows.Input.MouseButtonEventHandler]{
            param($sender, $e)
            $entry = Get-WinUtilAppEntryFromElement -Element $e.OriginalSource
            if ($entry) {
                # Store the selected app in a global variable so it can be used in the popup
                $sync.appPopupSelectedApp = $entry.Tag
                # Set the popup position to the current mouse position
                $sync.appPopup.PlacementTarget = $entry
                $sync.appPopup.IsOpen = $true
            }
        }
        # The checkbox sits inside the entry layout Grid, so the border is one level further up
        Checked = [Windows.RoutedEventHandler]{
            param($sender, $e)
            $checkBox = $e.OriginalSource
            if ($checkBox -is [Windows.Controls.CheckBox] -and $checkBox.Tag -is [string] -and $checkBox.Tag.StartsWith("WPFInstall")) {
                Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName $checkBox.Tag
                $checkBox.Parent.Parent.SetResourceReference([Windows.Controls.Border]::BackgroundProperty, "AppInstallSelectedColor")
            }
        }
        Unchecked = [Windows.RoutedEventHandler]{
            param($sender, $e)
            $checkBox = $e.OriginalSource
            if ($checkBox -is [Windows.Controls.CheckBox] -and $checkBox.Tag -is [string] -and $checkBox.Tag.StartsWith("WPFInstall")) {
                Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName $checkBox.Tag
                # Back to the style's colour, which also brings back its hover highlight
                $checkBox.Parent.Parent.ClearValue([Windows.Controls.Border]::BackgroundProperty)
            }
        }
        ImageFailed = {
            $this.Visibility = "Collapsed"
            $this.Parent.Children[0].Visibility = "Visible"
        }
    }

    return $script:WinUtilAppEntryHandlers
}
