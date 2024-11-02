function Show-OnlyCheckedApps {
    <#
        .SYNOPSIS
            Toggle between showing only the actively selected apps on the Install Tab and hiding everything else and displaying every app.
            If no apps are selected, dont do anything
        .PARAMETER appKeys
            Expects a List of appKeys that are selected at the moment
            If not provided, or empty, the function exits without any visual change to the ui
        .EXAMPLE
            Show-OnlyCheckedApps -appKeys $sync.SelectedApps
            Show-OnlyCheckedApps -appKeys ("WPFInstallChrome", "WPFInstall7zip")
    #>
    param (
        [Parameter(Mandatory=$false)]
        [String[]]$appKeys
    )
    # If no apps are selected, do not allow switching to show only selected
    if (($false -eq $sync.ShowOnlySelected) -and ($appKeys.Length -eq 0)) {
        Write-Host "No apps selected"
        $sync.wpfselectedfilter.IsChecked = $false
        return
    }
    $sync.ShowOnlySelected = -not $sync.ShowOnlySelected
    if ($sync.ShowOnlySelected) {
        $sync.Buttons | Where-Object {$_.Name -like "ShowSelectedAppsButton"} | ForEach-Object {
            $_.Content = "Show All"
        }

        $sync.ItemsControl.Items | Foreach-Object {
            # Search for App Container and set them to visible
            if ($_.Tag -like "CategoryWrapPanel_*") {
                $_.Visibility = [Windows.Visibility]::Visible
                # Iterate through all the apps in the container and set them to visible if they are in the appKeys array
                $_.Children | ForEach-Object {
                    if ($appKeys -contains $_.Tag) {
                        $_.Visibility = [Windows.Visibility]::Visible
                    }
                    else {
                        $_.Visibility = [Windows.Visibility]::Collapsed
                    }
                }
            }
            else {
                # Set all other items to collapsed
                $_.Visibility = [Windows.Visibility]::Collapsed
            }
        }
    } else {
        $sync.Buttons | Where-Object {$_.Name -like "ShowSelectedAppsButton"} | ForEach-Object {
            $_.Content = "Show Selected"
        }
        Set-CategoryVisibility -Category "*"
    }
}
