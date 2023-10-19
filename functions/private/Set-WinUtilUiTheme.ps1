function Set-WinUtilUITheme {
    <#

    .SYNOPSIS
        Sets the theme of the XAML file

    .PARAMETER inputXML
        A string representing the XAML object to modify

    .PARAMETER themeName
        The name of the theme to set the XAML to. Defaults to 'matrix'

    .EXAMPLE
        Set-WinUtilUITheme -inputXAML $inputXAML

    #>
    param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $inputXML,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $themeName = 'matrix'
    )

    try {
        # Convert the JSON to a PowerShell object
        $themes = $sync.configs.themes
        # Select the specified theme
        $selectedTheme = $themes.$themeName

        if ($selectedTheme) {
            # Loop through all key-value pairs in the selected theme
            foreach ($property in $selectedTheme.PSObject.Properties) {
                $key = $property.Name
                $value = $property.Value
                # Add curly braces around the key
                $formattedKey = "{$key}"
                # Replace the key with the value in the input XML
                $inputXML = $inputXML.Replace($formattedKey, $value)
            }
        }
        else {
            Write-Host "Theme '$themeName' not found."
        }

    }
    catch {
        Write-Warning "Unable to apply theme"
        Write-Warning $psitem.Exception.StackTrace
    }

    return $inputXML;
}
