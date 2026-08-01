function Sync-WPFMultiplaneOverlayState {
    param(
        [Parameter(Mandatory)]
        $ComboBox
    )

    $unknownStateText = "Custom / Unknown - select a state"
    $unknownStateItem = @($ComboBox.Items) | Where-Object Content -EQ $unknownStateText | Select-Object -First 1

    try {
        $currentState = Get-WinUtilMultiplaneOverlayState
        if ($unknownStateItem) {
            $ComboBox.Items.Remove($unknownStateItem)
        }

        $ComboBox.SelectedIndex = @($ComboBox.Items.Content).IndexOf($currentState)
        $ComboBox.Text = $currentState
        $ComboBox.ToolTip = $null
    } catch {
        if (-not $unknownStateItem) {
            $unknownStateItem = New-Object Windows.Controls.ComboBoxItem
            $unknownStateItem.Content = $unknownStateText
            $unknownStateItem.IsEnabled = $false
            $ComboBox.Items.Add($unknownStateItem) | Out-Null
        }

        $unknownStateItem.ToolTip = "$($_.Exception.Message) Select one of the supported states to replace these values."
        $ComboBox.SelectedItem = $unknownStateItem
        $ComboBox.Text = $unknownStateText
        $ComboBox.ToolTip = $unknownStateItem.ToolTip
    }
}
