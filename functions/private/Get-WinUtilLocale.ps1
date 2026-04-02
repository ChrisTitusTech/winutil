function Get-WinUtilLocale {
    <#
    .SYNOPSIS
        Determines which locale to use for the UI.
    .DESCRIPTION
        Priority: user preference > system language > "en"
        Returns a locale code string (e.g., "zh-TW", "ja", "en").
    #>

    $pref = $sync.preferences.locale
    if ($pref -and $pref -ne "auto") {
        return $pref
    }

    # Auto-detect from Windows system culture
    try {
        $culture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
        switch -Wildcard ($culture) {
            "zh-TW" { return "zh-TW" }
            "zh-HK" { return "zh-TW" }
            "zh-CN" { return "zh-CN" }
            "zh-SG" { return "zh-CN" }
            "zh-*"  { return "zh-CN" }
            "ja-*"  { return "ja" }
            "ko-*"  { return "ko" }
            "de-*"  { return "de" }
            "fr-*"  { return "fr" }
            "es-*"  { return "es" }
            "pt-BR" { return "pt-BR" }
            "ru-*"  { return "ru" }
            "vi-*"  { return "vi" }
            "th-*"  { return "th" }
            "ar-*"  { return "ar" }
            default  { return "en" }
        }
    } catch {
        return "en"
    }
}
