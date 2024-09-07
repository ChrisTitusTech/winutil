function Invoke-WPFChangeColor {

    $random = New-Object System.Random
    function Get-RandomColor {
        param (
            $type
        )
        $r = $random.Next(0, 256)
        $g = $random.Next(0, 256)
        $b = $random.Next(0, 256)
            if ($type -eq "Color"){
                return [Windows.Media.Color]::FromRgb($r, $g, $b)
            }
            else{
                return [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb($r, $g, $b))
            }
            
        }
        # Return a new SolidColorBrush with random RGB values

    $sync.Form.Resources["DComboBoxBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DLabelboxForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DMainForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DMainBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DLabelBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DLinkForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DComboBoxForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DProgressBarForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DProgressBarBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DProgressBarTextColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonInstallBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonTweaksBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonConfigBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonUpdatesBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonInstallForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonTweaksForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonConfigForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonUpdatesForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonBackgroundColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonBackgroundPressedColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonBackgroundMouseoverColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonBackgroundSelectedColor"] = Get-RandomColor
    $sync.Form.Resources["DButtonForegroundColor"] = Get-RandomColor
    $sync.Form.Resources["DToggleButtonOnColor"] = Get-RandomColor
    $sync.Form.Resources["DBorderColor"] = Get-RandomColor
    $sync.Form.Resources["CBorderColor"] = Get-RandomColor -type "Color"

}