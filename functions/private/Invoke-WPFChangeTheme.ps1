
function Invoke-WPFChangeTheme {
    param (
        $init = $false
    )
    function applyTheme{
        param (
            $ctttheme
        )
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
        $jsonRadius = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {($_.Name -like "*Radius*")} | Select-Object Name, Value
        foreach ($entry in $jsonRadius) {
            $sync.Form.Resources[$entry.Name] = [System.Windows.CornerRadius]::new($entry.Value)
        }
        $jsonRowHeight = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {($_.Name -like "*RowHeight*")} | Select-Object Name, Value
        foreach ($entry in $jsonRowHeight) {
            $sync.Form.Resources[$entry.Name] = [System.Windows.GridLength]::new($entry.Value)
        }

        $jsonThickness = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {($_.Name -like "*Thickness*") -or ($_.Name -like "*margin")} | Select-Object Name, Value
        foreach ($entry in $jsonThickness) {
            $values = $entry.Value -split ","
            switch ($values.Count) {
                1{$sync.Form.Resources[$entry.Name] = [System.Windows.Thickness]::new([double]$values[0])}
                2{$sync.Form.Resources[$entry.Name] = [System.Windows.Thickness]::new([double]$values[0],[double]$values[1])}
                4{$sync.Form.Resources[$entry.Name] = [System.Windows.Thickness]::new([double]$values[0],[double]$values[1],[double]$values[2],[double]$values[3])}
            }

            # Write-Host "$($entry.Name), $($sync.Form.Resources[$entry.Name])"
        }
        $jsonFontFamilys = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {$_.Name -like "*FontFamily*"} | Select-Object Name, Value
        foreach ($entry in $jsonFontFamilys) {
            $sync.Form.Resources[$entry.Name] = [Windows.Media.FontFamily]::new($entry.Value)
        }

        $jsonFontSize = $sync.configs.themes.$ctttheme.PSOBject.Properties | Where-Object {($_.Name -notlike "*color*") -and ($_.Name -notlike "*margin*")-and ($_.Name -notlike "*FontFamily*")-and ($_.Name -notlike "*thickness*") -and ($_.Name -notlike "*RowHeight*") -and ($_.Name -notlike "*Radius*")} | Select-Object Name, Value
        foreach ($entry in $jsonFontSize) {
            try {
                $sync.Form.Resources[$entry.Name] = [double]$entry.Value
                # Write-Host "$($entry.Name), $($entry.Value) Converted to double"
            }
            catch {
                # Write-Host "$($entry.Name), $($entry.Value) Could not be converted. Kept as a String"
                $sync.Form.Resources[$entry.Name] = $entry.Value

            }

        }

    }
    if ($init -eq $true) {
        if ((Get-WinUtilToggleStatus WPFToggleDarkMode) -eq $True) {

            $Script:ctttheme = "Dark"
        } else {
            $Script:ctttheme = "Light"
        }
        applyTheme -ctttheme "shared"
    }
    else{
        if ($ctttheme -eq "Dark") {
            $Script:ctttheme = "Light"
        }
        else {
            $Script:ctttheme = "Dark"
        }
    }

    switch ($ctttheme) {
        "Light"{
            $sync.Form.FindName("ThemeSelectorButton").Content = [char]0xE708
        }
        "Dark"{
            $sync.Form.FindName("ThemeSelectorButton").Content = [char]0xE706
        }
    }

    applyTheme -ctttheme $ctttheme

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
#endregion
