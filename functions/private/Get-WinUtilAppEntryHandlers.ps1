function Get-WinUtilAppEntryHandlers {
    <#
        .SYNOPSIS
            The event handlers shared by every app entry on the Install tab

        .DESCRIPTION
            A scriptblock literal inside a loop is a new scriptblock every time round, and
            building six of them per app is the single largest cost of drawing the app list:
            measured at 2.13 ms per entry against 0.62 ms when they are made once and reused.

            None of them close over anything per entry. They read the sender through $this, so
            one instance serves every app.
    #>

    if ($null -ne $script:WinUtilAppEntryHandlers) {
        return $script:WinUtilAppEntryHandlers
    }

    $script:WinUtilAppEntryHandlers = @{
        BorderClick = {
            # Resolve through $sync because the border's child is a layout Grid for FOSS entries
            $childCheckbox = $sync.$($this.Tag)
            $childCheckbox.IsChecked = -not $childCheckbox.IsChecked
        }
        MouseEnter = {
            if (($sync.$($this.Tag).IsChecked) -eq $false) {
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallHighlightedColor")
            }
        }
        MouseLeave = {
            if (($sync.$($this.Tag).IsChecked) -eq $false) {
                $this.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
            }
        }
        RightClick = {
            # Store the selected app in a global variable so it can be used in the popup
            $sync.appPopupSelectedApp = $this.Tag
            # Set the popup position to the current mouse position
            $sync.appPopup.PlacementTarget = $this
            $sync.appPopup.IsOpen = $true
        }
        # The checkbox sits inside the entry layout Grid, so the border is one level further up
        Checked = {
            Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName $this.Tag
            $borderElement = $this.Parent.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallSelectedColor")
        }
        Unchecked = {
            Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName $this.Tag
            $borderElement = $this.Parent.Parent
            $borderElement.SetResourceReference([Windows.Controls.Control]::BackgroundProperty, "AppInstallUnselectedColor")
        }
        ImageFailed = {
            $this.Visibility = "Collapsed"
            $this.Parent.Children[0].Visibility = "Visible"
        }
    }

    return $script:WinUtilAppEntryHandlers
}
