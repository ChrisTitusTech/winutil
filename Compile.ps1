param (
    [switch]$Run
)

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

$script = (Get-Content -Path scripts\start.ps1) -replace '#{replaceme}', (Get-Date -Format 'yy.MM.dd')

$script += Get-ChildItem -Path functions -Recurse -File | ForEach-Object {
    Get-Content -Path $_.FullName -Raw
}

Get-ChildItem config | ForEach-Object {
    $obj = Get-Content -Path $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

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

$xaml = Get-Content -Path xaml\inputXML.xaml -Raw
$script += "`$inputXML = @'`r`n$xaml`r`n'@"

$autounattendXml = Get-Content -Path tools\autounattend.xml -Raw
$script += "`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@"

$script += Get-Content -Path scripts\main.ps1 -Raw

# Write via .NET API so the encoding is identical on PowerShell 5.1 (Set-Content
# defaults to ANSI) and 7+ (utf8NoBOM): UTF8Encoding($false) omits a BOM, so the
# prepended [char]0xFEFF becomes the BOM on both versions ([Type]::new() is PS 5.0+).
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) "winutil.ps1"),
    [string][char]0xFEFF + $script,
    [System.Text.UTF8Encoding]::new($false)
)

if ($Run) {
    .\Winutil.ps1
}
