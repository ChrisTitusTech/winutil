#Requires -Version 5.1
<#
.SYNOPSIS
    Retrieves a localized string from a JSON resource file.
.DESCRIPTION
    This function looks up a string by its key in a language-specific JSON file.
    It supports string formatting with provided arguments and includes fallback logic
    to the default language (English) if a translation is missing.
.PARAMETER Key
    The unique key for the desired string (e.g., "mainWindow.title"). This is mandatory.
.PARAMETER LanguageCode
    The IETF language tag (e.g., "en", "zh", "es") for the desired language.
    If not provided, it attempts to use $Global:UserSelectedLanguage.
    If that's also not set, it defaults to "en".
.PARAMETER FormatArguments
    An array of objects to be used for formatting the string if it contains
    placeholders (e.g., "{0}", "{1}").
.EXAMPLE
    Get-LocalizedString -Key "myApp.greeting"
    # Returns "Hello" if 'en' is the current/default language and "myApp.greeting" is "Hello".

.EXAMPLE
    Get-LocalizedString -Key "myApp.welcomeMessage" -FormatArguments "John"
    # If "myApp.welcomeMessage" is "Welcome, {0}!", returns "Welcome, John!".

.EXAMPLE
    Get-LocalizedString -Key "myApp.farewell" -LanguageCode "zh"
    # Attempts to retrieve the Chinese translation for "myApp.farewell".
    # Falls back to English if not found in Chinese.
.NOTES
    The language JSON files are expected to be in the 'i18n' directory relative
    to the script's execution path (e.g., '$PSScriptRoot/../i18n/en.json' or '$PSScriptRoot/../../i18n/en.json'
    depending on where Get-LocalizedString.ps1 is located relative to the i18n dir).
    The function assumes a project structure where 'i18n' is a sibling to the 'functions' directory or its parent.
    It tries to locate the 'i18n' directory by going up one or two levels from the script's own directory.
.OUTPUTS
    System.String
    The localized (and optionally formatted) string, or a placeholder if the string is not found.
#>
function Get-LocalizedString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$LanguageCode,

        [Parameter(Mandatory = $false)]
        [object[]]$FormatArguments
    )

    # Determine the language code to use
    [string]$currentLanguage = "en" # Default language
    if (-not [string]::IsNullOrEmpty($LanguageCode)) {
        $currentLanguage = $LanguageCode
    }
    elseif ($Global:PSBoundParameters.ContainsKey('UserSelectedLanguage') -and (-not [string]::IsNullOrEmpty($Global:UserSelectedLanguage))) {
        $currentLanguage = $Global:UserSelectedLanguage
    }

    # Try to determine the base path for i18n directory
    # This assumes Get-LocalizedString.ps1 is in functions/private/
    # So, ../../i18n/ would be the path from the script file.
    # However, $PSScriptRoot might not be reliable if the function is dot-sourced or imported differently.
    # Let's try a path relative to the main script's execution path if possible,
    # or assume a known structure. For now, using a path relative to this script.
    # Adjust this path if your project structure is different.
    $basePath = Resolve-Path (Join-Path $PSScriptRoot "..") # Go up one level from 'private' to 'functions'
    $i18nBasePath = Join-Path $basePath ".." # Go up one level from 'functions' to project root
    $i18nDir = Join-Path $i18nBasePath "i18n"

    [string]$resolvedString = $null
    [bool]$foundInPrimary = $false

    # Construct the path to the language file
    $langFilePath = Join-Path $i18nDir "$($currentLanguage).json"

    if (Test-Path $langFilePath) {
        try {
            $langContent = Get-Content -Path $langFilePath -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($langContent.PSObject.Properties[$Key]) {
                $resolvedString = $langContent.PSObject.Properties[$Key].Value
                $foundInPrimary = $true
            }
        }
        catch {
            Write-Warning "Error reading or parsing language file '$langFilePath': $($_.Exception.Message)"
        }
    }

    # Fallback to default language if not found and not already trying default
    if (-not $foundInPrimary -and $currentLanguage -ne "en") {
        $defaultLangFilePath = Join-Path $i18nDir "en.json"
        if (Test-Path $defaultLangFilePath) {
            try {
                $defaultLangContent = Get-Content -Path $defaultLangFilePath -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($defaultLangContent.PSObject.Properties[$Key]) {
                    $resolvedString = $defaultLangContent.PSObject.Properties[$Key].Value
                }
            }
            catch {
                Write-Warning "Error reading or parsing default language file '$defaultLangFilePath': $($_.Exception.Message)"
            }
        }
    }

    # Format the string if arguments are provided
    if ($resolvedString -ne $null -and $FormatArguments) {
        try {
            # Using -f operator for formatting
            $resolvedString = $resolvedString -f $FormatArguments
        }
        catch {
            Write-Warning "Error formatting string for key '$Key' with arguments '$($FormatArguments -join ', ')': $($_.Exception.Message)"
            # Return the unformatted string in case of formatting error, or a specific error message
            $resolvedString = "FORMAT_ERROR: $Key"
        }
    }

    # Return the string or a placeholder
    if ($resolvedString -ne $null) {
        return $resolvedString
    }
    else {
        return "MISSING_TRANSLATION: $Key"
    }
}

# Export the function if this script is sourced as a module (optional, depends on usage)
# For direct sourcing or if functions are discovered differently, this might not be strictly necessary.
# Export-ModuleMember -Function Get-LocalizedString

Write-Host "Get-LocalizedString.ps1 loaded" # For debugging if sourced directly
