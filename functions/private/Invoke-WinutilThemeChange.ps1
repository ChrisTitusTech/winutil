function Invoke-WinutilThemeChange {
    <#
    .SYNOPSIS
        Toggles between light and dark themes for a Windows utility application.

    .DESCRIPTION
        This function toggles the theme of the user interface between 'Light' and 'Dark' modes,
        modifying various UI elements such as colors, margins, corner radii, font families, etc.
        If the '-init' switch is used, it initializes the theme based on the system's current dark mode setting.

    .PARAMETER init
        A switch parameter. If set to $true, the function initializes the theme based on the system’s current dark mode setting.

    .EXAMPLE
        Invoke-WinutilThemeChange
        # Toggles the theme between 'Light' and 'Dark'.

    .EXAMPLE
        Invoke-WinutilThemeChange -init
        # Initializes the theme based on the system's dark mode and applies the shared theme.
    #>
    param (
        [switch]$init = $false,
        [string]$theme
    )

    function Set-WinutilTheme {
        <#
        .SYNOPSIS
            Applies the specified theme to the application's user interface.

        .DESCRIPTION
            This internal function applies the given theme by setting the relevant properties
            like colors, font families, corner radii, etc., in the UI. It uses the
            'Set-ThemeResourceProperty' helper function to modify the application's resources.

        .PARAMETER currentTheme
            The name of the theme to be applied. Common values are "Light", "Dark", or "shared".
        #>
        param (
            [string]$currentTheme
        )

        function Set-ThemeResourceProperty {
            <#
            .SYNOPSIS
                Sets a specific UI property in the application's resources.

            .DESCRIPTION
                This helper function sets a property (e.g., color, margin, corner radius) in the
                application's resources, based on the provided type and value. It includes
                error handling to manage potential issues while setting a property.

            .PARAMETER Name
                The name of the resource property to modify (e.g., "MainBackgroundColor", "ButtonBackgroundMouseoverColor").

            .PARAMETER Value
                The value to assign to the resource property (e.g., "#FFFFFF" for a color).

            .PARAMETER Type
                The type of the resource, such as "ColorBrush", "CornerRadius", "GridLength", or "FontFamily".
            #>
            param($Name, $Value, $Type)
            try {
                # Set the resource property based on its type
                $sync.Form.Resources[$Name] = switch ($Type) {
                    "ColorBrush" { [Windows.Media.SolidColorBrush]::new($Value) }
                    "Color" {
                        # Convert hex string to RGB values
                        $hexColor = $Value.TrimStart("#")
                        $r = [Convert]::ToInt32($hexColor.Substring(0,2), 16)
                        $g = [Convert]::ToInt32($hexColor.Substring(2,2), 16)
                        $b = [Convert]::ToInt32($hexColor.Substring(4,2), 16)
                        [Windows.Media.Color]::FromRgb($r, $g, $b)
                    }
                    "CornerRadius" { [System.Windows.CornerRadius]::new($Value) }
                    "GridLength" { [System.Windows.GridLength]::new($Value) }
                    "Thickness" {
                        # Parse the Thickness value (supports 1, 2, or 4 inputs)
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
                # Log a warning if there's an issue setting the property
                Write-Warning "Failed to set property $($Name): $_"
            }
        }

        # Retrieve all theme properties from the theme configuration
        $themeProperties = $sync.configs.themes.$currentTheme.PSObject.Properties
        foreach ($_ in $themeProperties) {
            # Apply properties that deal with colors
            if ($_.Name -like "*color*") {
                Set-ThemeResourceProperty -Name $_.Name -Value $_.Value -Type "ColorBrush"
                # For certain color properties, also set complementary values (e.g., BorderColor -> CBorderColor) This is required because e.g DropShadowEffect requires a <Color> and not a <SolidColorBrush> object
                if ($_.Name -in @("BorderColor", "ButtonBackgroundMouseoverColor")) {
                    Set-ThemeResourceProperty -Name "C$($_.Name)" -Value $_.Value -Type "Color"
                }
            }
            # Apply corner radius properties
            elseif ($_.Name -like "*Radius*") {
                Set-ThemeResourceProperty -Name $_.Name -Value $_.Value -Type "CornerRadius"
            }
            # Apply row height properties
            elseif ($_.Name -like "*RowHeight*") {
                Set-ThemeResourceProperty -Name $_.Name -Value $_.Value -Type "GridLength"
            }
            # Apply thickness or margin properties
            elseif (($_.Name -like "*Thickness*") -or ($_.Name -like "*margin")) {
                Set-ThemeResourceProperty -Name $_.Name -Value $_.Value -Type "Thickness"
            }
            # Apply font family properties
            elseif ($_.Name -like "*FontFamily*") {
                Set-ThemeResourceProperty -Name $_.Name -Value $_.Value -Type "FontFamily"
            }
            # Apply any other properties as doubles (numerical values)
            else {
                Set-ThemeResourceProperty -Name $_.Name -Value $_.Value -Type "Double"
            }
        }
    }

    $LightPreferencePath = "$winutildir\LightTheme.ini"
    $DarkPreferencePath = "$winutildir\DarkTheme.ini"

    if ($init) {
        Set-WinutilTheme -currentTheme "shared"
        if (Test-Path $LightPreferencePath) {
            $theme = "Light"
        }
        elseif (Test-Path $DarkPreferencePath) {
            $theme = "Dark"
        }
        else {
            $theme = "Auto"
        }
    }

    switch ($theme) {
        "Auto" {
            $systemUsesDarkMode = Get-WinUtilToggleStatus WPFToggleDarkMode
            if ($systemUsesDarkMode) {
                Set-WinutilTheme  -currentTheme "Dark"
            }
            else{
                Set-WinutilTheme  -currentTheme "Light"
            }


            $themeButtonIcon = [char]0xF08C
            Remove-Item $LightPreferencePath -Force -ErrorAction SilentlyContinue
            Remove-Item $DarkPreferencePath -Force -ErrorAction SilentlyContinue
        }
        "Dark" {
            Set-WinutilTheme  -currentTheme $theme
            $themeButtonIcon = [char]0xE708
            $null = New-Item $DarkPreferencePath -Force
            Remove-Item $LightPreferencePath -Force -ErrorAction SilentlyContinue
           }
        "Light" {
            Set-WinutilTheme  -currentTheme $theme
            $themeButtonIcon = [char]0xE706
            $null = New-Item $LightPreferencePath -Force
            Remove-Item $DarkPreferencePath -Force -ErrorAction SilentlyContinue
        }
    }

    # Set FOSS Highlight Color
    $fossEnabled = $true
    if ($sync.WPFToggleFOSSHighlight) {
        $fossEnabled = $sync.WPFToggleFOSSHighlight.IsChecked
    }

    if ($fossEnabled) {
         $sync.Form.Resources["FOSSColor"] = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(76, 175, 80)) # #4CAF50
    } else {
         $sync.Form.Resources["FOSSColor"] = $sync.Form.Resources["MainForegroundColor"]
    }

    # Update the theme selector button with the appropriate icon
    $ThemeButton = $sync.Form.FindName("ThemeButton")
    $ThemeButton.Content = [string]$themeButtonIcon
}
