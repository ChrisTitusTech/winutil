function Set-WinUtilLanguage {
    <#
    .SYNOPSIS
        Switches the UI language immediately: persists the preference, rebuilds
        rendered config entries, and re-applies static text injection.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("en", "zh-CN")]
        [string]$Language
    )

    $sync.language = $Language
    if ($Language -eq "en") {
        $sync.TextTable = $null
    } else {
        $table = @{}
        $sync.configs.i18n.$Language.strings.PSObject.Properties |
            ForEach-Object { $table[$_.Name] = [string]$_.Value }
        $sync.TextTable = $table
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
    Apply-WinUtilUILanguage
}
