param (
    [switch]$Run,
    [switch]$Trace
)

$OFS = "`r`n"

function Remove-WinUtilPerformanceTraceCalls {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    if ($Trace) {
        return $Content
    }

    $filteredLines = $Content -split "`r?`n" | Where-Object {
        $_ -notmatch '^\s*(Start-WinUtilPerformanceTrace|Stop-WinUtilPerformanceTrace|Write-WinUtilPerformanceCheckpoint)\b'
    }

    $filteredLines -join "`r`n"
}

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

$script = (Get-Content -Path scripts\start.ps1) -replace '#{replaceme}', (Get-Date -Format 'yy.MM.dd')

$script += Get-ChildItem -Path functions -Recurse -File | ForEach-Object {
    Remove-WinUtilPerformanceTraceCalls -Content (Get-Content -Path $_.FullName -Raw)
}

if ($Trace) {
    $script += Get-ChildItem -Path tools\perf -Filter *.ps1 -File | Get-Content -Raw

    $script += @'
$sync.PerformanceTraceEnabled = $true
Start-WinUtilPerformanceTrace
Write-WinUtilPerformanceCheckpoint -Name "Config load start"
'@
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
    if ($Trace) {
        $script += "`r`nWrite-WinUtilPerformanceCheckpoint -Name `"Config $($_.BaseName) loaded`""
    }
}

if ($Trace) {
    $script += "`r`nWrite-WinUtilPerformanceCheckpoint -Name `"Config load complete`""
}

$xaml = Get-Content -Path xaml\inputXML.xaml -Raw
$script += "`$inputXML = @'`r`n$xaml`r`n'@"

$autounattendXml = Get-Content -Path tools\autounattend.xml -Raw
$script += "`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@"

$script += Remove-WinUtilPerformanceTraceCalls -Content (Get-Content -Path scripts\main.ps1 -Raw)

Set-Content -Path winutil.ps1 -Value $script

if ($Run) {
    .\Winutil.ps1
}
