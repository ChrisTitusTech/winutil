param (
    [switch]$Run
)

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

$script = (Get-Content -Path scripts\start.ps1) -replace '#{replaceme}', (Get-Date -Format 'yy.MM.dd')
$isLocalCompile = -not [string]::Equals($env:GITHUB_ACTIONS, "true", [StringComparison]::OrdinalIgnoreCase)
$script = $script -replace '#{islocalcompile}', $isLocalCompile.ToString().ToLowerInvariant()

$script += Get-ChildItem -Path functions -Recurse -File | ForEach-Object {
    Get-Content -Path $_.FullName -Raw
}

Get-ChildItem config -File -Filter *.json | ForEach-Object {
    $obj = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json

    if ($_.Name -eq "applications.json") {
        $fixed = [ordered]@{}
        foreach ($p in $obj.PSObject.Properties) {
            $fixed["WPFInstall$($p.Name)"] = $p.Value
        }
        $obj = [pscustomobject]$fixed
    }

    $json = $obj | ConvertTo-Json -Depth 10

    $sync.configs[$_.BaseName] = $obj
    $script += "`$sync.configs.$($_.BaseName) = @'`r`n$json`r`n'@ | ConvertFrom-Json"
}

# Icons are one PNG per app in config\icons\<key>.png, named after the key in applications.json.
# They ship as a single key -> base64 map, which the Install tab reads from $sync.configs.icons.
$icons = [ordered]@{}
Get-ChildItem config\icons -File -Filter *.png | ForEach-Object {
    $icons[$_.BaseName] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($_.FullName))
}
$iconsObject = [pscustomobject]$icons
$sync.configs["icons"] = $iconsObject
$script += "`$sync.configs.icons = @'`r`n$($iconsObject | ConvertTo-Json)`r`n'@ | ConvertFrom-Json"

$xaml = Get-Content -Path xaml\inputXML.xaml -Raw
$script += "`$inputXML = @'`r`n$xaml`r`n'@"

$autounattendXml = Get-Content -Path tools\autounattend.xml -Raw
$script += "`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@"

$script += Get-Content -Path scripts\main.ps1 -Raw

Set-Content -Path winutil.ps1 -Value $script

if ($Run) {
    .\Winutil.ps1
}
