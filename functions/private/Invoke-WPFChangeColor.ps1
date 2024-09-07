
function Invoke-WPFChangeColor {
    param (
        $init = $false
    )
    if ($init -eq $true) {
        if ((Get-WinUtilToggleStatus WPFToggleDarkMode) -eq $True) {

            $Script:ctttheme = "Dark"
        } else {
            $Script:ctttheme = "_default"
        }
    }
    else{
        if ($ctttheme -eq "Dark") {
            $Script:ctttheme = "_default"
        }
        else {
            $Script:ctttheme = "Dark"
        }
    }

    switch ($ctttheme) {
        "_default"{
            $sync.Form.FindName("ThemeSelectorButton").Content = [char]0xE708
        }
        "Dark"{
            $sync.Form.FindName("ThemeSelectorButton").Content = [char]0xE706
        }
    }

    # Colors are stored as a SolidColorBrush Object
    $jsonColors = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {$_.Name -like "*color*"} | Select-Object Name, Value
    foreach ($entry in $jsonColors) {
        $sync.Form.Resources[$($entry.Name)] = [Windows.Media.SolidColorBrush]::new($entry.Value)

        # Because Border color is also used in a Drop Shadow, it's nesessary to also store it as a Color Resource
        if ($($entry.Name) -eq "BorderColor") {
            $hexColor = $entry.Value.TrimStart("#")
            $r = [Convert]::ToInt32($hexColor.Substring(0, 2), 16)
            $g = [Convert]::ToInt32($hexColor.Substring(2, 2), 16)
            $b = [Convert]::ToInt32($hexColor.Substring(4, 2), 16)
            $sync.Form.Resources["CBorderColor"] = [Windows.Media.Color]::FromRgb($r, $g, $b)
        }
    }
    # Opacity is storead as a number
    $jsonOpacity = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {$_.Name -like "*opacity*"} | Select-Object Name, Value
    foreach ($entry in $jsonOpacity) {
        $sync.Form.Resources[$entry.Name] = [double]$entry.Value
    }

    # $random = New-Object System.Random
    # function Get-RandomColor {
    #     param (
    #         $type
    #     )
    #     $r = $random.Next(0, 256)
    #     $g = $random.Next(0, 256)
    #     $b = $random.Next(0, 256)
    #         if ($type -eq "Color") {
    #             return [Windows.Media.Color]::FromRgb($r, $g, $b)
    #         }
    #         else{
    #             return [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb($r, $g, $b))
    #         }

    #     }
    #     # Return a new SolidColorBrush with random RGB values

    # $sync.Form.Resources["DComboBoxBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DLabelboxForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DMainForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DMainBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DLabelBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DLinkForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DComboBoxForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DProgressBarForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DProgressBarBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DProgressBarTextColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonInstallBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonTweaksBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonConfigBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonUpdatesBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonInstallForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonTweaksForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonConfigForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonUpdatesForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonBackgroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonBackgroundPressedColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonBackgroundMouseoverColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonBackgroundSelectedColor"] = Get-RandomColor
    # $sync.Form.Resources["DButtonForegroundColor"] = Get-RandomColor
    # $sync.Form.Resources["DToggleButtonOnColor"] = Get-RandomColor
    # $sync.Form.Resources["DBorderColor"] = Get-RandomColor
    # $sync.Form.Resources["CBorderColor"] = Get-RandomColor -type "Color"

}
