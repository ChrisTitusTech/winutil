function Get-LocalizedString {
    param(
        [AllowEmptyString()][string]$Key,
        [string]$Language
    )

    if ($null -eq $Key -or [string]::IsNullOrWhiteSpace($Key)) {
        return $Key
    }

    # Determine language: explicit, preferences, or system culture
    if (-not $Language) {
        if ($sync -and $sync.preferences -and $sync.preferences.language) {
            $Language = $sync.preferences.language
        } else {
            $Language = (Get-Culture).Name.Split('-')[0]
        }
    }

    # Normalize to two-letter code
    $langCode = $Language.Substring(0,2).ToLower()

    # Build candidate locations by walking up from $PSScriptRoot and from current directory
    $candidates = @()
    $startDirs = @($PSScriptRoot, (Get-Location).Path)
    foreach ($start in $startDirs) {
        $cur = $start
        for ($i = 0; $i -lt 6; $i++) {
            if (-not [string]::IsNullOrWhiteSpace($cur)) {
                $candidates += Join-Path $cur "i18n\ui.$langCode.json"
                $cur = Split-Path -Path $cur -Parent
            }
        }
    }

    # Also consider same-folder and one-level up patterns used by the compiler
    $candidates += Join-Path $PSScriptRoot "..\..\i18n\ui.$langCode.json"
    $candidates += Join-Path $PSScriptRoot "..\i18n\ui.$langCode.json"

    $resPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    # Fallback to English if not found
    if (-not $resPath) {
        $langCode = 'en'
        $candidates = @()
        foreach ($start in $startDirs) {
            $cur = $start
            for ($i = 0; $i -lt 6; $i++) {
                if (-not [string]::IsNullOrWhiteSpace($cur)) {
                    $candidates += Join-Path $cur "i18n\ui.$langCode.json"
                    $cur = Split-Path -Path $cur -Parent
                }
            }
        }
        $candidates += Join-Path $PSScriptRoot "..\..\i18n\ui.$langCode.json"
        $candidates += Join-Path $PSScriptRoot "..\i18n\ui.$langCode.json"
        $resPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    if (-not $resPath) {
        Write-Debug "Localization files not found in expected locations. Searched: $($candidates -join ';')"
        return $Key
    }

    try {
        $json = Get-Content -Path $resPath -Raw | ConvertFrom-Json
        $value = $null
        if ($json -is [System.Collections.IDictionary]) {
            $value = $json[$Key]
        } else {
            $value = $json.$($Key)
        }
        if ($value) { return $value }
    } catch {
        Write-Debug ("Failed to read localization file {0}: {1}" -f $resPath, $_)
    }

    return $Key
}
