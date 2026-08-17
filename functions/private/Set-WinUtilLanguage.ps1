function Set-WinUtilLanguage {
    <#
    .SYNOPSIS
        Switches the UI language immediately: persists the preference, rebuilds
        rendered config entries, and re-applies static text injection. On
        failure the previous language state is restored and the error logged,
        so a failed switch never leaves the UI half-translated.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("en", "zh-CN")]
        [string]$Language
    )

    $previousLanguage = $sync.language
    $previousTextTable = $sync.TextTable
    $previousReverseTextTable = $sync.ReverseTextTable

    try {
        $sync.language = $Language
        if ($Language -eq "en") {
            # Keep a value->key reverse table from the outgoing language so
            # static text already translated can be restored to English.
            $sync.TextTable = $null
            $reverse = @{}
            if ($null -ne $previousTextTable) {
                foreach ($entry in $previousTextTable.GetEnumerator()) {
                    $reverse[[string]$entry.Value] = [string]$entry.Key
                }
            }
            $sync.ReverseTextTable = $reverse
        } else {
            $table = @{}
            $sync.configs.i18n.$Language.strings.PSObject.Properties |
                ForEach-Object { $table[$_.Name] = [string]$_.Value }
            $sync.TextTable = $table
            $sync.ReverseTextTable = $null
        }

        # Persist preference alongside logs
        $prefPath = Join-Path $sync.winutildir "preferences.json"
        Set-Content -Path $prefPath -Value (@{ language = $Language } | ConvertTo-Json) -Encoding UTF8

        # Rebuild every already-rendered tab so config entries re-render in the new language
        $tabGridMap = @{
            "Install"  = @("appscategory", "appspanel")
            "Tweaks"   = @("tweakspanel")
            "Config"   = @("featurespanel")
            "AppX"     = @("appxpanel")
        }
        foreach ($tabName in @($sync.InitializedTabs.Keys)) {
            foreach ($gridName in $tabGridMap[$tabName]) {
                $grid = $sync[$gridName]
                if ($grid) { $grid.Children.Clear() }
            }
        }
        $sync.InitializedTabs = @{}
        Initialize-WinUtilTabContent -TabName $sync.currentTab

        # Re-apply static text (tab headers, menus, tooltips)
        Invoke-WinUtilUILanguage
    } catch {
        $sync.language = $previousLanguage
        $sync.TextTable = $previousTextTable
        $sync.ReverseTextTable = $previousReverseTextTable
        Write-WinUtilLog -Component "i18n" -Message "Failed to switch language: $_"
    }
}
