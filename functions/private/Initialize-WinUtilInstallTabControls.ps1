function Initialize-WinUtilInstallTabControls {
    <#
        .SYNOPSIS
            Wires the Install tab controls that are generated from config rather than declared
            in XAML

        .DESCRIPTION
            The package manager radio buttons and the install action buttons are created by
            Invoke-WPFUIElements, so they do not exist until the Install tab is built. Setting
            them up anywhere other than immediately after that build makes the code depend on
            when the tab happens to be created.
    #>

    if ($sync.ChocoRadioButton) {
        $sync.ChocoRadioButton.Add_Checked({
            $sync.preferences.packagemanager = "Choco"
        })
    }
    if ($sync.WingetRadioButton) {
        $sync.WingetRadioButton.Add_Checked({
            $sync.preferences.packagemanager = "Winget"
        })
    }

    switch ($sync.preferences.packagemanager) {
        "Choco" { if ($sync.ChocoRadioButton) { $sync.ChocoRadioButton.IsChecked = $true }; break }
        "Winget" { if ($sync.WingetRadioButton) { $sync.WingetRadioButton.IsChecked = $true }; break }
    }

    if ($PARAM_OFFLINE) {
        foreach ($name in "WPFInstall", "WPFUninstall", "WPFInstallUpgrade", "WPFGetInstalled") {
            if ($sync.$name) { $sync.$name.IsEnabled = $false }
        }
    }
}
