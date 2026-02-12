function Invoke-WinUtilLocaleUpdate {
    <#
    .SYNOPSIS
        Checks for and downloads locale JSON files for WinUtil localization.
    .PARAMETER Language
        The language code to update (e.g., "fr-FR").
    #>
    param (
        [string]$Language
    )

    if ([string]::IsNullOrWhiteSpace($Language) -or $Language -eq "en-US") {
        return
    }

    # If already loaded, skip
    if ($sync.configs.locales -and $sync.configs.locales[$Language]) {
        return
    }

    $localeDir = "$env:LocalAppData\winutil\locales"
    if (!(Test-Path $localeDir)) {
        New-Item -Path $localeDir -ItemType Directory -Force | Out-Null
    }

    $localeFile = "$localeDir\$Language.json"
    $downloadUrl = "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/locales/$Language.json"

    # Try to load from cache first
    if (Test-Path $localeFile) {
        try {
            $json = Get-Content $localeFile -Raw -Encoding UTF8
            $sync.configs.locales[$Language] = $json | ConvertFrom-Json
            Write-Debug "Loaded locale $Language from cache."
            return
        }
        catch {
            Write-Warning "Failed to load cached locale $Language. Re-downloading."
        }
    }

    # Development/Testing: Check if the file exists locally in the config folder
    # This is useful when running from the source tree or for testing before pushing to GitHub
    $localSourceFile = Join-Path $PSScriptRoot "config\locales\$Language.json"
    if (Test-Path $localSourceFile) {
        try {
            $json = Get-Content $localSourceFile -Raw -Encoding UTF8
            $sync.configs.locales[$Language] = $json | ConvertFrom-Json
            # Cache it so we don't have to keep reading from source
            $json | Set-Content -Path $localeFile -Encoding UTF8
            Write-Host "Loaded locale $Language from local source: $localSourceFile"
            return
        }
        catch {
            Write-Warning "Failed to load locale $Language from local source."
        }
    }

    # Download from GitHub
    try {
        Write-Host "Downloading locale: $Language..."
        $json = Invoke-RestMethod -Uri $downloadUrl -Method Get

        # Invoke-RestMethod returns an object if it's JSON, but we might want the raw string to cache it properly or handle it
        # Actually, let's use Invoke-WebRequest for raw content and then convert
        $response = Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing
        $jsonContent = $response.Content

        # Save to cache
        $jsonContent | Set-Content -Path $localeFile -Encoding UTF8

        # Load into sync
        $sync.configs.locales[$Language] = $jsonContent | ConvertFrom-Json
        Write-Host "Successfully downloaded and loaded locale: $Language"
    }
    catch {
        Write-Warning "Failed to download locale $Language from GitHub. Falling back to English."
    }
}
