function Initialize-WinUtilLanguage {
    <#
    .SYNOPSIS
        Loads the persisted language preference and sets $sync.language /
        $sync.TextTable. English is the default (no preference or unknown code).
    #>

    $sync.language = "en"
    $sync.TextTable = $null

    $prefPath = Join-Path $sync.winutildir "preferences.json"
    if (-not (Test-Path $prefPath)) { return }

    try {
        $prefs = Get-Content $prefPath -Raw | ConvertFrom-Json
        $code = [string]$prefs.language
        if ($code -ne "en" -and $sync.configs.i18n.PSObject.Properties.Name -contains $code) {
            $sync.language = $code
            $table = @{}
            $sync.configs.i18n.$code.strings.PSObject.Properties |
                ForEach-Object { $table[$_.Name] = [string]$_.Value }
            $sync.TextTable = $table
        }
    } catch {
        Write-WinUtilLog -Component "i18n" -Message "Failed to load language preference: $_"
    }
}
