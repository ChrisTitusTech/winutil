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
        [switch]$init = $false
    )

    function Set-WinutilTheme {
        <#
        .SYNOPSIS
            Applies the specified theme to the application's user interface.

        .DESCRIPTION
            This internal function applies the given theme by setting the relevant properties
            like colors, font families, corner radii, etc., in the UI. It uses the
            'Set-ResourceProperty' helper function to modify the application's resources.

        .PARAMETER ctttheme
            The name of the theme to be applied. Common values are "Light", "Dark", or "shared".
        #>
        param (
            [string]$ctttheme
        )

        function Set-ResourceProperty {
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
        $themeProperties = $sync.configs.themes.$ctttheme.PSObject.Properties
        foreach ($_ in $themeProperties) {
            # Apply properties that deal with colors
            if ($_.Name -like "*color*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "ColorBrush"
                # For certain color properties, also set complementary values (e.g., BorderColor -> CBorderColor) This is required because e.g DropShadowEffect requires a <Color> and not a <SolidColorBrush> object 
                if ($_.Name -in @("BorderColor", "ButtonBackgroundMouseoverColor")) {
                    Set-ResourceProperty -Name "C$($_.Name)" -Value $_.Value -Type "Color"
                }
            }
            # Apply corner radius properties
            elseif ($_.Name -like "*Radius*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "CornerRadius"
            }
            # Apply row height properties
            elseif ($_.Name -like "*RowHeight*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "GridLength"
            }
            # Apply thickness or margin properties
            elseif (($_.Name -like "*Thickness*") -or ($_.Name -like "*margin")) {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "Thickness"
            }
            # Apply font family properties
            elseif ($_.Name -like "*FontFamily*") {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "FontFamily"
            }
            # Apply any other properties as doubles (numerical values)
            else {
                Set-ResourceProperty -Name $_.Name -Value $_.Value -Type "Double"
            }
        }
    }

    # If init is true, initialize the theme based on the system's dark mode setting
    if ($init -eq $true) {
        $systemUsesDarkMode = Get-WinUtilToggleStatus WPFToggleDarkMode
        # Set theme based on system dark mode status
        $sync.ctttheme = $systemUsesDarkMode ? "Dark" : "Light"
        Set-WinutilTheme -ctttheme "shared"
    }
    else {
        # Toggle the theme between 'Dark' and 'Light'
        $sync.ctttheme -eq "Dark" ? ($sync.ctttheme = "Light") : ($sync.ctttheme = "Dark")
    }

    # Apply the new theme
    Set-WinutilTheme -ctttheme $sync.ctttheme

    # Update the theme selector button with the appropriate icon and tooltip
    $themeIcon = $sync.ctttheme -eq "Light" ? ([char]0xE708) : ([char]0xE706) # Icon based on current theme
    $toolTip = $sync.ctttheme -eq "Light" ? "Use Dark Mode" : "Use Light Mode" # Tooltip based on current theme
    $ThemeSelectorButton = $sync.Form.FindName("ThemeSelectorButton")
    $ThemeSelectorButton.Content = [string]$themeIcon
    $ThemeSelectorButton.toolTip = $toolTip
}
