function Invoke-WinutilThemeChange {
    param (
        [switch]$init = $false
    )

    function Set-WinutilTheme {
        param (
            [string]$ctttheme
        )

        function Set-ResourceProperty {
            param($Name, $Value, $Type)
            try {
                $sync.Form.Resources[$Name] = switch ($Type) {
                    "ColorBrush" { [Windows.Media.SolidColorBrush]::new($Value) }
                    "Color" {
                        $hexColor = $Value.TrimStart("#")
                        $r = [Convert]::ToInt32($hexColor.Substring(0,2), 16)
                        $g = [Convert]::ToInt32($hexColor.Substring(2,2), 16)
                        $b = [Convert]::ToInt32($hexColor.Substring(4,2), 16)
                        [Windows.Media.Color]::FromRgb($r, $g, $b)
                    }
                    "CornerRadius" { [System.Windows.CornerRadius]::new($Value) }
                    "GridLength" { [System.Windows.GridLength]::new($Value) }
                    "Thickness" {
                        $values = $Value -split ","
                        switch ($values.Count) {
                            1 { [System.Windows.Thickness]::new([double]$values[0]) }
                            2 { [System.Windows.Thickness]::new([double]$values[0], [double]$values[1]) }
                            4 { [System.Windows.Thickness]::new([double]$values[0], [double]$values[1], [double]$values[2], [double]$values[3]) }
                        }
                    }
                    "FontFamily" { [Windows.Media.FontFamily]::new($Value) }
                    "Double" { [double]$Value }
                    default { $Value }
                }
            }
            catch {
                Write-Warning "Failed to set property $($Name): $_"
            }
        }
        $themeProperties = $sync.configs.themes.$ctttheme.PSOBject.Properties
        foreach ($_ in $themeProperties) {
            if ($_.Name -like "*color*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "ColorBrush"
                if ($_.Name -in @("BorderColor", "ButtonBackgroundMouseoverColor")) {
                    Set-ResourceProperty -Name "C$($_.Name)" -Value $_.Value -Type "Color"
                }
            }
            elseif ($_.Name -like "*Radius*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "CornerRadius"
            }
            elseif ($_.Name -like "*RowHeight*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "GridLength"
            }
            elseif (($_.Name -like "*Thickness*") -or ($_.Name -like "*margin")) {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "Thickness"
            }
            elseif ($_.Name -like "*FontFamily*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "FontFamily"
            }
            else{
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "Double"
            }
        }
    }

    if ($init -eq $true) {
        $systemUsesDarkMode = Get-WinUtilToggleStatus WPFToggleDarkMode
        $sync.ctttheme = $systemUsesDarkMode ? "Dark" : "Light"
        Set-WinutilTheme -ctttheme "shared"
    }
    else {
        $sync.ctttheme -eq "Dark" ? ($sync.ctttheme = "Light") : ($sync.ctttheme = "Dark")
    }
    Set-WinutilTheme -ctttheme $sync.ctttheme

    # Update the Button to reflect the Theme
    $themeIcon = $sync.ctttheme -eq "Light" ? ([char]0xE708) : ([char]0xE706)
    $toolTip = $sync.ctttheme -eq "Light" ? "Use Dark Mode" : "Use Light Mode"
    $ThemeSelectorButton = $sync.Form.FindName("ThemeSelectorButton")
    $ThemeSelectorButton.Content = [string]$themeIcon
    $ThemeSelectorButton.toolTip = $toolTip
}
