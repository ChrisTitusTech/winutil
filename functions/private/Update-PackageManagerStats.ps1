function Update-PackageManagerStats {
    <#
        .SYNOPSIS
            Updates the display of package manager statistics in the UI
    #>

    try {
        # Get current stats
        $stats = Get-PackageManagerStats

        # Update radio button content with app counts (optional enhancement)
        if ($sync.WingetRadioButton) {
            $sync.WingetRadioButton.Content = "Winget ($($stats.Winget))"
        }

        if ($sync.ChocoRadioButton) {
            $sync.ChocoRadioButton.Content = "Chocolatey ($($stats.Chocolatey))"
        }

        # Update tooltips with more detailed info

        if ($sync.WingetRadioButton) {
            $sync.WingetRadioButton.ToolTip = "Show $($stats.Winget) applications available via Winget"
        }

        if ($sync.ChocoRadioButton) {
            $sync.ChocoRadioButton.ToolTip = "Show $($stats.Chocolatey) applications available via Chocolatey`n($($stats.Both) applications support both managers)"
        }

        Write-Host "Package Manager Stats: Winget=$($stats.Winget), Chocolatey=$($stats.Chocolatey), Both=$($stats.Both)"

    } catch {
        Write-Warning "Failed to update package manager stats: $($_.Exception.Message)"
    }
}
