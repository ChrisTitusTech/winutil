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
    param (
         [Parameter(Mandatory, position=0)]
         [string] $inputXML,
         [Parameter(position=1)]
         [string] $themeName = 'matrix'
    )

    function Invoke-Theming {
        param (
            [Parameter(Mandatory, position=0)]
            [string] $XMLToProcess,

            [Parameter(Mandatory, position=1)]
            [PSCustomObject] $theme
        )

        if ($XMLToProcess -eq "") {
            throw [GenericException]::new("[Invoke-Theming] 'XMLToProcess' can not be an empty string")
        }

        try {
            # Loop through all key-value pairs in the selected theme
            foreach ($property in $theme.PSObject.Properties) {
                $key = $property.Name
                $value = $property.Value
                # Add curly braces around the key
                $formattedKey = "{$key}"
                # Replace the key with the value in the input XML
                $XMLToProcess = $XMLToProcess.Replace($formattedKey, $value)
            }
        } catch {
            throw [GenericException]::new("[Invoke-Theming] Failed to apply theme, StackTrace: $($psitem.Exception.StackTrace)")
        }

        return $XMLToProcess
    }


    try {
        # Convert the JSON to a PowerShell object
        $themes = $sync.configs.themes
        if (-NOT $themes) {
            throw [GenericException]::new("[Set-WinUtilTheme] Did not find 'config.themes' inside `$sync variable.")
        }

        $defaultTheme = $themes."_default"
        if (-NOT $defaultTheme) {
            throw [GenericException]::new("[Set-WinUtilTheme] Did not find '_default' theme in the themes config file.")
        }

        # First apply the selected theme (if it exists), then apply the default theme
        $selectedTheme = $themes.$themeName
        if (-NOT $selectedTheme) {
            Write-Warning "[Set-WinUtilTheme] Theme '$themeName' was not found."
        } else {
            $inputXML = Invoke-Theming -XMLToProcess $inputXML -theme $selectedTheme
        }

        $inputXML = Invoke-Theming -XMLToProcess $inputXML -theme $defaultTheme

    }
    catch {
        Write-Warning "[Set-WinUtilTheme] Unable to apply theme"
        $err = $psitem.Exception.StackTrace
        Write-Warning $err
    }

    $returnVal = @{
        err="$err";
        processedXML="$inputXML";
    }

    return $returnVal;
}
