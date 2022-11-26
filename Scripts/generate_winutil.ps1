$XAML = (Get-Content .\MainWindow.xaml -Encoding utf8 -Raw) -replace "'",""
$configs = @{}
(
    "applications", 
    "tweaks",
    "preset", 
    "feature"
) | ForEach-Object {
    $configs["$PSItem"] = Get-Content .\config\$PSItem.json -Encoding utf8 -Raw
}
$winutil = Get-Content ./winutil.ps1 -Encoding utf8 -Raw    

@"

`$inputXML = '$XAML'
`$preset = '$($configs.preset)' | convertfrom-json
`$tweaks = '$($configs.tweaks)' | convertfrom-json
`$applications = '$($configs.applications)' | convertfrom-json
`$feature = '$($configs.feature)' | convertfrom-json
$winutil

"@ | Out-File winutil-generated.ps1