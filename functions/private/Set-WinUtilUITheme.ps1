function Set-WinUtilUITheme {
    <#
        .SYNOPSIS
            Sets the theme of the XAML file

        .PARAMETER inputXML
            A string representing the XAML object to modify

        .PARAMETER customThemeName
            The name of the custom theme to set the XAML to. Defaults to 'matrix'

        .PARAMETER defaultThemeName
            The name of the default theme to use when setting the XAML. Defaults to '_default'

        .EXAMPLE
            Set-WinUtilUITheme -inputXAML $inputXAML
    #>

    param (
        [Parameter(Mandatory, position=0)]
        [string]$inputXML,

        [Parameter(position=1)]
        [string]$customThemeName = 'matrix',

        [Parameter(position=2)]
        [string]$defaultThemeName = '_default'
    )

    try {
        # Note:
        #    Reason behind not caching the '$sync.configs.themes` object into a variable,
        #    because this code can modify the themes object.. meaning it's better to access it
        #    using the more verbose way, rather than introduce possible bugs into the code, just for the sake of readability.
        #
        if (-NOT $sync.configs.themes) {
            throw [GenericException]::new("[Set-WinUtilTheme] Did not find 'config.themes' inside `$sync variable.")
        }

        if (-NOT $sync.configs.themes.$defaultThemeName) {
            throw [GenericException]::new("[Set-WinUtilTheme] Did not find '$defaultThemeName' theme in the themes config file.")
        }

        if ($sync.configs.themes.$customThemeName) {
            # Loop through every default theme option, and modify the custom theme in $sync variable,
            # so that it has full options available for other functions to use.
            foreach ($option in $sync.configs.themes.$defaultThemeName.PSObject.Properties) {
                $optionName = $option.Name
                $optionValue = $option.Value
                if (-NOT $sync.configs.themes.$customThemeName.$optionName) {
                    $sync.configs.themes.$customThemeName | Add-Member -MemberType NoteProperty -Name $optionName -Value $optionValue
                }
            }
        } else {
            Write-Debug "[Set-WinUtilTheme] Theme '$customThemeName' was not found."
        }

        foreach ($property in $sync.configs.themes.$customThemeName.PSObject.Properties) {
            $key = $property.Name
            $value = $property.Value
            # Add curly braces around the key
            $formattedKey = "{$key}"
            # Replace the key with the value in the input XML
            $inputXML = $inputXML.Replace($formattedKey, $value)
        }
    }
    catch {
        Write-Host "[Set-WinUtilTheme] Unable to apply theme" -ForegroundColor Red
        Write-Host "$($psitem.Exception.Message)" -ForegroundColor Red
        $inputXML = "" # Make inputXML equal an empty string, indicating something went wrong to the function caller.
    }

    return $inputXML;
}
