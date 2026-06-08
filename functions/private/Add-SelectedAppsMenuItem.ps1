function Add-SelectedAppsMenuItem {
    <#
        .SYNOPSIS
            Adds a menu item to the selected apps popup for a given app key
        .PARAMETER name
            The name of the application to display
        .PARAMETER key
            The key of the application
    #>
    param($name, $key)

    $menuItem = New-Object Windows.Controls.MenuItem
    $menuItem.Header = $name
    $menuItem.Tag = $key

    $menuItem.Add_Click({
        param($sender, $e)
        $key = $sender.Tag
        if ($sync.$key) {
            $sync.$key.IsChecked = $false
        }
    })

    $sync.selectedAppsstackPanel.Children.Add($menuItem) | Out-Null
}
