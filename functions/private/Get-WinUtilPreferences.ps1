function Get-WinUtilPreferencesPath {
    <# Returns the on-disk path for persisted preferences. #>
    if ($null -ne $sync -and $sync.ContainsKey("winutildir") -and -not [string]::IsNullOrWhiteSpace($sync.winutildir)) {
        return Join-Path $sync.winutildir "preferences.json"
    }
    return $null
}

function Get-WinUtilPreferences {
    <#
        .SYNOPSIS
            Loads persisted preferences into $sync.preferences.

        .DESCRIPTION
            Reads %LocalAppData%\winutil\preferences.json when present. Missing keys fall back to
            the defaults passed in -Defaults. A missing or malformed file is not an error.
    #>
    param(
        [hashtable]$Defaults = @{ theme = "Auto"; packagemanager = "Winget"; language = "en" }
    )

    foreach ($key in $Defaults.Keys) { $sync.preferences[$key] = $Defaults[$key] }

    $path = Get-WinUtilPreferencesPath
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { return }

    try {
        $saved = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($key in $Defaults.Keys) {
            $prop = $saved.PSObject.Properties[$key]
            if ($null -ne $prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
                $sync.preferences[$key] = [string]$prop.Value
            }
        }
    } catch { }
}

function Save-WinUtilPreferences {
    <#
        .SYNOPSIS
            Persists the current $sync.preferences to disk.
    #>
    $path = Get-WinUtilPreferencesPath
    if (-not $path) { return }

    try {
        if (-not (Test-Path -LiteralPath (Split-Path -Parent $path))) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        }
        $toSave = [ordered]@{
            theme          = [string]$sync.preferences.theme
            packagemanager = [string]$sync.preferences.packagemanager
            language       = [string]$sync.preferences.language
        }
        $toSave | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $path -Encoding UTF8
    } catch { }
}
