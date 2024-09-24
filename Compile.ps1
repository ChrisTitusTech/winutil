param (
    [switch]$Debug,
    [switch]$Run,
    [switch]$SkipPreprocessing,
    [string]$Arguments
)

if ((Get-Item ".\winutil.ps1" -ErrorAction SilentlyContinue).IsReadOnly) {
    Remove-Item ".\winutil.ps1" -Force
}

$OFS = "`r`n"
$scriptname = "winutil.ps1"
$workingdir = $PSScriptRoot

Push-Location
Set-Location $workingdir

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $workingdir
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

$header = @"
################################################################################################################
###                                                                                                          ###
### WARNING: This file is automatically generated DO NOT modify this file directly as it will be overwritten ###
###                                                                                                          ###
################################################################################################################
"@

if (-NOT $SkipPreprocessing) {
    Update-Progress "Pre-req: Running Preprocessor..." 0

    # Dot source the 'Invoke-Preprocessing' Function from 'tools/Invoke-Preprocessing.ps1' Script
    $preprocessingFilePath = ".\tools\Invoke-Preprocessing.ps1"
    . $preprocessingFilePath

    $excludedFiles = @('.\.git\', '.\.gitignore', '.\.gitattributes', '.\.github\CODEOWNERS', '.\LICENSE', "$preprocessingFilePath", '*.png', '*.exe')
    $msg = "Pre-req: Code Formatting"
    Invoke-Preprocessing -WorkingDir "$workingdir" -ExcludedFiles $excludedFiles -ProgressStatusMessage $msg -ThrowExceptionOnEmptyFilesList
}

# Create the script in memory.
Update-Progress "Pre-req: Allocating Memory" 0
$script_content = [System.Collections.Generic.List[string]]::new()

Update-Progress "Adding: Header" 5
$script_content.Add($header)

Update-Progress "Adding: Version" 10
$script_content.Add($(Get-Content "scripts\start.ps1").replace('#{replaceme}',"$(Get-Date -Format yy.MM.dd)"))

Update-Progress "Adding: Functions" 20
Get-ChildItem "functions" -Recurse -File | ForEach-Object {
    $script_content.Add($(Get-Content $psitem.FullName))
    }
Update-Progress "Adding: Config *.json" 40
Get-ChildItem "config" | Where-Object {$psitem.extension -eq ".json"} | ForEach-Object {
    $json = @"
        $((Get-Content $psitem.FullName -Raw).replace("'","''"))
"@
    $jsonAsObject = $json | ConvertFrom-Json

    # Add 'WPFInstall' as a prefix to every entry-name in 'applications.json' file
    if ($psitem.Name -eq "applications.json") {
        foreach ($appEntryName in $jsonAsObject.PSObject.Properties.Name) {
            $appEntryContent = $jsonAsObject.$appEntryName
            $jsonAsObject.PSObject.Properties.Remove($appEntryName)
            $jsonAsObject | Add-Member -MemberType NoteProperty -Name "WPFInstall$appEntryName" -Value $appEntryContent
        }
    }

    $json = @"
        $($jsonAsObject | ConvertTo-Json -Depth 3)
"@

    $sync.configs.$($psitem.BaseName) = $json | ConvertFrom-Json
    $script_content.Add($(Write-Output "`$sync.configs.$($psitem.BaseName) = '$json' `| ConvertFrom-Json" ))
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

$script_content.Add($(Get-Content "scripts\main.ps1"))

if ($Debug) {
    Update-Progress "Writing debug files" 95
    $appXamlContent | Out-File -FilePath "xaml\inputApp.xaml" -Encoding ascii
    $tweaksXamlContent | Out-File -FilePath "xaml\inputTweaks.xaml" -Encoding ascii
    $featuresXamlContent | Out-File -FilePath "xaml\inputFeatures.xaml" -Encoding ascii
} else {
    Update-Progress "Removing temporary files" 99
    Remove-Item "xaml\inputApp.xaml" -ErrorAction SilentlyContinue
    Remove-Item "xaml\inputTweaks.xaml" -ErrorAction SilentlyContinue
    Remove-Item "xaml\inputFeatures.xaml" -ErrorAction SilentlyContinue
}

Set-Content -Path "$scriptname" -Value ($script_content -join "`r`n") -Encoding ascii
Write-Progress -Activity "Compiling" -Completed

Update-Progress -Activity "Validating" -StatusMessage "Checking winutil.ps1 Syntax" -Percent 0
try {
    $null = Get-Command -Syntax .\winutil.ps1
} catch {
    Write-Warning "Syntax Validation for 'winutil.ps1' has failed"
    Write-Host "$($Error[0])" -ForegroundColor Red
}
Write-Progress -Activity "Validating" -Completed

if ($run) {
    $script = "& '$workingdir\$scriptname' $Arguments"

    $powershellcmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $powershellcmd }

    Start-Process $processCmd -ArgumentList "$powershellcmd -NoProfile -Command $script"

    break
}
Pop-Location
