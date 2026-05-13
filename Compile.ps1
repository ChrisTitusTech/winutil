param (
    [switch]$Run
)

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

# Create the script in memory.
$script = [System.Collections.Generic.List[string]]::new()

$script.Add(
    ((Get-Content scripts\start.ps1) -replace '#{replaceme}', (Get-Date -Format 'yy.MM.dd'))
)

$script.Add((Get-ChildItem functions -Recurse -File | Get-Content))

Get-ChildItem config -Filter *.json | ForEach-Object {
    $obj = Get-Content $_.FullName | ConvertFrom-Json

    if ($_.Name -eq "applications.json") {
        $fixed = [ordered]@{}
        foreach ($p in $obj.PSObject.Properties) {
            $fixed["WPFInstall$($p.Name)"] = $p.Value
        }
        $obj = [pscustomobject]$fixed
    }

    $json = $obj | ConvertTo-Json -Depth 10

    $sync.configs[$_.BaseName] = $obj
    $script.Add("`$sync.configs.$($_.BaseName) = @'`r`n$json`r`n'@ | ConvertFrom-Json")
}

# Read the entire XAML file as a single string, preserving line breaks
$xaml = Get-Content xaml\inputXML.xaml
$script.Add('$inputXML = @''' + "`n" + $xaml + "`n" + '''@')

$autounattendXml = Get-Content "tools\autounattend.xml"
$script.Add("`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@")

$script.Add((Get-Content scripts\main.ps1))

Set-Content -Path winutil.ps1 -Value $script

if ($run) {
    .\Winutil.ps1
}
