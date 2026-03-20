param (
    [switch]$Run,
    [string]$Arguments
)

if ((Get-Item ".\winutil.ps1" -ErrorAction SilentlyContinue).IsReadOnly) {
    Remove-Item ".\winutil.ps1" -Force
}

$OFS = "`r`n"
$scriptname = "winutil.ps1"
$workingdir = $PSScriptRoot

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

function Update-Progress {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$StatusMessage,

        [Parameter(Mandatory, position=1)]
        [ValidateRange(0,100)]
        [int]$Percent,

        [Parameter(position=2)]
        [string]$Activity = "Compiling"
    )

    Write-Progress -Activity $Activity -Status $StatusMessage -PercentComplete $Percent
}

Update-Progress "Pre-req: Running Preprocessor..." 0

# Dot source the 'Invoke-Preprocessing' Function from 'tools/Invoke-Preprocessing.ps1' Script
$preprocessingFilePath = ".\tools\Invoke-Preprocessing.ps1"
. $preprocessingFilePath

$excludedFiles = @()

# Add directories only if they exist
if (Test-Path '.\.git\') { $excludedFiles += '.\.git\' }
if (Test-Path '.\binary\') { $excludedFiles += '.\binary\' }

# Add files that should always be excluded
$excludedFiles += @(
    '.\.gitignore',
    '.\.gitattributes',
    '.\.github\CODEOWNERS',
    '.\LICENSE',
    "$preprocessingFilePath",
    '*.png',
    '.\.preprocessor_hashes.json'
)

$msg = "Pre-req: Code Formatting"
Invoke-Preprocessing -WorkingDir "$workingdir" -ExcludedFiles $excludedFiles -ProgressStatusMessage $msg

# Create the script in memory.
Update-Progress "Pre-req: Allocating Memory" 0
$script_content = [System.Collections.Generic.List[string]]::new()

Update-Progress "Adding: Version" 10
$script_content.Add($(Get-Content "scripts\start.ps1").replace('#{replaceme}',"$(Get-Date -Format yy.MM.dd)"))

Update-Progress "Adding: Functions" 20
Get-ChildItem "functions" -Recurse -File | ForEach-Object {
    $script_content.Add($(Get-Content $psitem.FullName))
    }
Update-Progress "Adding: Config *.json" 40
Get-ChildItem "config" | Where-Object {$psitem.extension -eq ".json"} | ForEach-Object {
    $json = (Get-Content $psitem.FullName -Raw)
    $jsonAsObject = $json | ConvertFrom-Json

    # Add 'WPFInstall' as a prefix to every entry-name in 'applications.json' file
    if ($psitem.Name -eq "applications.json") {
        foreach ($appEntryName in $jsonAsObject.PSObject.Properties.Name) {
            $appEntryContent = $jsonAsObject.$appEntryName
            $jsonAsObject.PSObject.Properties.Remove($appEntryName)
            $jsonAsObject | Add-Member -MemberType NoteProperty -Name "WPFInstall$appEntryName" -Value $appEntryContent
        }
    }

    # Line 90 requires no whitespace inside the here-strings, to keep formatting of the JSON in the final script.
    $json = @"
$($jsonAsObject | ConvertTo-Json -Depth 3)
"@

    $sync.configs.$($psitem.BaseName) = $json | ConvertFrom-Json
    $script_content.Add($(Write-Output "`$sync.configs.$($psitem.BaseName) = @'`r`n$json`r`n'@ `| ConvertFrom-Json" ))
}

# Read the entire XAML file as a single string, preserving line breaks
$xaml = Get-Content "$workingdir\xaml\inputXML.xaml" -Raw

Update-Progress "Adding: Xaml " 90

# Add the XAML content to $script_content using a here-string
$script_content.Add(@"
`$inputXML = @'
$xaml
'@
"@)

Update-Progress "Adding: autounattend.xml" 95
$autounattendRaw = Get-Content "$workingdir\tools\autounattend.xml" -Raw
# Strip XML comments (<!-- ... -->, including multi-line)
$autounattendRaw = [regex]::Replace($autounattendRaw, '<!--.*?-->', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
# Drop blank lines and trim trailing whitespace per line
$autounattendXml = ($autounattendRaw -split "`r?`n" |
    Where-Object { $_.Trim() -ne '' } |
    ForEach-Object { $_.TrimEnd() }) -join "`r`n"
$script_content.Add(@"
`$WinUtilAutounattendXml = @'
$autounattendXml
'@
"@)

$script_content.Add($(Get-Content "scripts\main.ps1"))

Update-Progress "Removing temporary files" 99
Remove-Item "xaml\inputApp.xaml" -ErrorAction SilentlyContinue
Remove-Item "xaml\inputTweaks.xaml" -ErrorAction SilentlyContinue
Remove-Item "xaml\inputFeatures.xaml" -ErrorAction SilentlyContinue

Set-Content -Path "$scriptname" -Value ($script_content -join "`r`n") -Encoding ascii
Write-Progress -Activity "Compiling" -Completed

Update-Progress -Activity "Validating" -StatusMessage "Checking winutil.ps1 Syntax" -Percent 0
try {
    Get-Command -Syntax .\winutil.ps1 | Out-Null
} catch {
    Write-Warning "Syntax Validation for 'winutil.ps1' has failed"
    Write-Host "$($Error[0])" -ForegroundColor Red
    exit 1
}
Write-Progress -Activity "Validating" -Completed

if ($run) {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\Winutil.ps1 $Arguments
    break
}
