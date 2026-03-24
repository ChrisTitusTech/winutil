function Invoke-WPFLocalization {
    <#
    .SYNOPSIS
        Applies locale translations to config objects before UI generation.
    .DESCRIPTION
        Loads the locale JSON (from embedded data or file) and overlays
        translated Content/Description onto $sync.configs.* objects.
        Must be called BEFORE applicationsHashtable creation and UI generation.
    #>

    $localeCode = Get-WinUtilLocale
    if ($localeCode -eq "en") {
        Write-Debug "Locale: en (no translation needed)"
        return
    }

    # Try embedded locale data first (compiled script), then file (dev mode)
    $locale = $null
    if ($sync.locales -and $sync.locales[$localeCode]) {
        $locale = $sync.locales[$localeCode]
    } else {
        $localePath = Join-Path $sync.PSScriptRoot "config\locales\$localeCode.json"
        if (Test-Path $localePath) {
            try {
                $locale = Get-Content $localePath -Raw -Encoding UTF8 | ConvertFrom-Json
            } catch {
                Write-Debug "Failed to parse locale file: $localePath"
                return
            }
        }
    }

    if (-not $locale) {
        Write-Debug "Locale '$localeCode' not available"
        return
    }

    $sync.currentLocale = $locale
    $applied = 0

    # Apply to tweaks
    if ($locale.tweaks) {
        foreach ($prop in $locale.tweaks.PSObject.Properties) {
            $target = $sync.configs.tweaks.$($prop.Name)
            if ($target) {
                if ($prop.Value.Content) { $target.Content = $prop.Value.Content; $applied++ }
                if ($prop.Value.Description) { $target.Description = $prop.Value.Description; $applied++ }
            }
        }
    }

    # Apply to applications (locale keys don't have WPFInstall prefix)
    if ($locale.applications) {
        foreach ($prop in $locale.applications.PSObject.Properties) {
            $configKey = "WPFInstall$($prop.Name)"
            $target = $sync.configs.applications.$configKey
            if ($target) {
                if ($prop.Value.description) { $target.description = $prop.Value.description; $applied++ }
            }
        }
    }

    # Apply to feature
    if ($locale.feature) {
        foreach ($prop in $locale.feature.PSObject.Properties) {
            $target = $sync.configs.feature.$($prop.Name)
            if ($target) {
                if ($prop.Value.Content) { $target.Content = $prop.Value.Content; $applied++ }
                if ($prop.Value.Description) { $target.Description = $prop.Value.Description; $applied++ }
            }
        }
    }

    # Apply to appnavigation
    if ($locale.appnavigation) {
        foreach ($prop in $locale.appnavigation.PSObject.Properties) {
            $target = $sync.configs.appnavigation.$($prop.Name)
            if ($target) {
                if ($prop.Value.Content) { $target.Content = $prop.Value.Content; $applied++ }
                if ($prop.Value.Description) { $target.Description = $prop.Value.Description; $applied++ }
            }
        }
    }

    # Apply category translations to config objects
    if ($locale.categories) {
        $catMap = @{}
        foreach ($prop in $locale.categories.PSObject.Properties) {
            $catMap[$prop.Name] = $prop.Value
        }
        $sync.categoryTranslations = $catMap
    }

    Write-Host "Locale: $localeCode ($($locale._meta.name)) - $applied strings applied" -ForegroundColor Green
}
