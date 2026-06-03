function Invoke-WinutilThemeChange ($theme) {
    $sync.preferences.theme = $theme

    function Set-Prop($name, $value, $type) {
        $sync.Form.Resources[$name] = switch ($type) {
            "ColorBrush" {
                [Windows.Media.SolidColorBrush]::new($value)
            }
            "Color" {
                $h = $value.TrimStart("#")
                [Windows.Media.Color]::FromRgb(
                    [Convert]::ToInt32($h.Substring(0,2),16),
                    [Convert]::ToInt32($h.Substring(2,2),16),
                    [Convert]::ToInt32($h.Substring(4,2),16)
                )
            }
            "CornerRadius" { [System.Windows.CornerRadius]::new($value) }
            "GridLength"   { [System.Windows.GridLength]::new($value) }
            "Thickness" {
                $v = $value -split ","
                if ($v.Count -eq 1) { [System.Windows.Thickness]::new($v[0]) }
                elseif ($v.Count -eq 2) { [System.Windows.Thickness]::new($v[0],$v[1]) }
                else { [System.Windows.Thickness]::new($v[0],$v[1],$v[2],$v[3]) }
            }
            "FontFamily" { [Windows.Media.FontFamily]::new($value) }
            "Double" { [double]$value }
            default { $value }
        }
    }

    function ApplyTheme($name) {
        foreach ($p in $sync.configs.themes.$name.PSObject.Properties) {

            if ($p.Name -like "*color*") {
                Set-Prop $p.Name $p.Value "ColorBrush"

                if ($p.Name -in "BorderColor","ButtonBackgroundMouseoverColor") {
                    Set-Prop "C$($p.Name)" $p.Value "Color"
                }
            }
            elseif ($p.Name -like "*Radius*") { Set-Prop $p.Name $p.Value "CornerRadius" }
            elseif ($p.Name -like "*RowHeight*") { Set-Prop $p.Name $p.Value "GridLength" }
            elseif ($p.Name -like "*Thickness*" -or $p.Name -like "*margin*") { Set-Prop $p.Name $p.Value "Thickness" }
            elseif ($p.Name -like "*FontFamily*") { Set-Prop $p.Name $p.Value "FontFamily" }
            else { Set-Prop $p.Name $p.Value "Double" }
        }
    }

    ApplyTheme "shared"

    if ($theme -eq "Auto") {
        $theme = if (Get-WinUtilToggleStatus WPFToggleDarkMode) { "Dark" } else { "Light" }
    }

    ApplyTheme $theme

    $icon = switch ($theme) {
        "Dark"  { [char]0xE708 }
        "Light" { [char]0xE706 }
        default { [char]0xF08C }
    }

    $toggle = $sync.WPFToggleFOSSHighlight

    $fossEnabled =
        if ($null -eq $toggle) { $true }
        else { $toggle.IsChecked -ne $false }

    $sync.Form.Resources["FOSSColor"] =
        if ($fossEnabled) {
            [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(76,175,80))
        } else {
            $sync.Form.Resources["MainForegroundColor"]
        }

    ($sync.Form.FindName("ThemeButton")).Content = [string]$icon
}
