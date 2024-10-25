function Microwin-GetLangFromCulture {

    param (
        [Parameter(Mandatory, Position = 0)] [string]$langName
    )

    switch -Wildcard ($langName)
    {
        "ar*" { return "Arabic" }
        "pt-BR" { return "Brazilian Portuguese" }
        "bg*" { return "Bulgarian" }
        {($_ -eq "zh-CH") -or ($_ -like "zh-Hans*") -or ($_ -eq "zh-SG") -or ($_ -eq "zh-CHS")} { return "Chinese (Simplified)" }
        {($_ -eq "zh") -or ($_ -eq "zh-Hant") -or ($_ -eq "zh-HK") -or ($_ -eq "zh-MO") -or ($_ -eq "zh-TW") -or ($_ -eq "zh-CHT")} { return "Chinese (Traditional)" }
        "hr*" { return "Croatian" }
        "cs*" { return "Czech" }
        "da*" { return "Danish" }
        "nl*" { return "Dutch" }
        "en-US" { return "English" }
        {($_ -like "en*") -and ($_ -ne "en-US")} { return "English International" }
        "et*" { return "Estonian" }
        "fi*" { return "Finnish" }
        {($_ -like "fr*") -and ($_ -ne "fr-CA")} { return "French" }
        "fr-CA" { return "French Canadian" }
        "de*" { return "German" }
        "el*" { return "Greek" }
        "he*" { return "Hebrew" }
        "hu*" { return "Hungarian" }
        "it*" { return "Italian" }
        "ja*" { return "Japanese" }
        "ko*" { return "Korean" }
        "lv*" { return "Latvian" }
        "lt*" { return "Lituanian" }
        "nb*" { return "Norwegian" }
        "pl*" { return "Polish" }
        {($_ -like "pt*") -and ($_ -ne "pt-BR")} { return "Portuguese" }
        "ro*" { return "Romanian" }
        "ru*" { return "Russian" }
        "sr-Latn*" { return "Serbian Latin" }
        "sk*" { return "Slovak" }
        "sl*" { return "Slovenian" }
        {($_ -like "es*") -and ($_ -ne "es-MX")} { return "Spanish" }
        "es-MX" { return "Spanish (Mexico)" }
        "sv*" { return "Swedish" }
        "th*" { return "Thai" }
        "tr*" { return "Turkish" }
        "uk*" { return "Ukrainian" }
        default { return "English" }
    }
}
