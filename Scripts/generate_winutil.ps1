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
$form = Get-Content ./scripts/form.ps1 -Encoding utf8 -Raw    
$functions = Get-Content ./scripts/functions.ps1 -Encoding utf8 -Raw    
$winutil = Get-Content ./scripts/main.ps1 -Encoding utf8 -Raw    

@"
`$inputXML = '$XAML'
`$preset = '$($configs.preset)' | convertfrom-json
`$tweaks = '$($configs.tweaks)' | convertfrom-json
`$applications = '$($configs.applications)' | convertfrom-json
`$feature = '$($configs.feature)' | convertfrom-json
$form
$functions
$winutil
"@ | Out-File winutil.ps1