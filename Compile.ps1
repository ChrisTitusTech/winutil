param (
    [switch]$Run,

    # The release tag to stamp as the version. Defaults to the build date, which is what CI
    # tags with. Pass the real tag when a release does not match the date, as happens when a
    # second release is cut on the same day, so the About dialog's version link resolves.
    [ValidatePattern('^\d{2}\.\d{2}\.\d{2}(\.\d+)?$')]
    [string]$Version = (Get-Date -Format 'yy.MM.dd'),

    # Mark the output as a published build rather than a local one, as a CI build is marked.
    [switch]$Release
)

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

$script = (Get-Content -Path scripts\start.ps1) -replace '#{replaceme}', $Version
$isLocalCompile = -not ($Release -or [string]::Equals($env:GITHUB_ACTIONS, "true", [StringComparison]::OrdinalIgnoreCase))
$script = $script -replace '#{islocalcompile}', $isLocalCompile.ToString().ToLowerInvariant()

$script += Get-ChildItem -Path functions -Recurse -File | ForEach-Object {
    Get-Content -Path $_.FullName -Raw
}

Get-ChildItem config | ForEach-Object {
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

$xaml = Get-Content -Path xaml\inputXML.xaml -Raw
$script += "`$inputXML = @'`r`n$xaml`r`n'@"

$autounattendXml = Get-Content -Path tools\autounattend.xml -Raw
$script += "`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@"

$script += Get-Content -Path scripts\main.ps1 -Raw

Set-Content -Path winutil.ps1 -Value $script

if ($Run) {
    .\Winutil.ps1
}
