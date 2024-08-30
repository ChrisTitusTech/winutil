param (
    [switch]$Debug,
    [switch]$Run,
    [switch]$SkipPreprocessing,
    [string]$arg
)
$OFS = "`r`n"
$scriptname = "winutil.ps1"
$workingdir = $PSScriptRoot

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
    . "$(($workingdir -replace ('\\$', '')) + '\' + ($preprocessingFilePath -replace ('\.\\', '')))"

    $excludedFiles = @('.\.git\', '.\.gitignore', '.\.gitattributes', '.\.github\CODEOWNERS', '.\LICENSE', "$preprocessingFilePath", '*.png', '*.exe')
    $msg = "Pre-req: Code Formatting"
    Invoke-Preprocessing -WorkingDir "$workingdir" -ExcludedFiles $excludedFiles -ProgressStatusMessage $msg
}

# Create the script in memory.
Update-Progress "Pre-req: Allocating Memory" 0
$script_content = [System.Collections.Generic.List[string]]::new()

Update-Progress "Adding: Header" 5
$script_content.Add($header)

Update-Progress "Adding: Version" 10
$script_content.Add($(Get-Content "$workingdir\scripts\start.ps1").replace('#{replaceme}',"$(Get-Date -Format yy.MM.dd)"))

Update-Progress "Adding: Functions" 20
Get-ChildItem "$workingdir\functions" -Recurse -File | ForEach-Object {
    $script_content.Add($(Get-Content $psitem.FullName))
    }
Update-Progress "Adding: Config *.json" 40
Get-ChildItem "$workingdir\config" | Where-Object {$psitem.extension -eq ".json"} | ForEach-Object {
    $json = (Get-Content $psitem.FullName).replace("'","''")
    $jsonAsObject = $json | convertfrom-json

    # Add 'WPFInstall' as a prefix to every entry-name in 'applications.json' file
    if ($psitem.Name -eq "applications.json") {
        foreach ($appEntryName in $jsonAsObject.PSObject.Properties.Name) {
            $appEntryContent = $jsonAsObject.$appEntryName
            $jsonAsObject.PSObject.Properties.Remove($appEntryName)
            $jsonAsObject | Add-Member -MemberType NoteProperty -Name "WPFInstall$appEntryName" -Value $appEntryContent
        }
    }

    # The replace at the end is required, as without it the output of 'converto-json' will be somewhat weird for Multiline Strings
    # Most Notably is the scripts in some json files, making it harder for users who want to review these scripts, which're found in the compiled script
    $json = ($jsonAsObject | convertto-json -Depth 3).replace('\r\n',"`r`n")

    $sync.configs.$($psitem.BaseName) = $json | convertfrom-json
    $script_content.Add($(Write-output "`$sync.configs.$($psitem.BaseName) = '$json' `| convertfrom-json" ))
}

$xaml = (Get-Content "$workingdir\xaml\inputXML.xaml").replace("'","''")

Update-Progress "Adding: Xaml " 90

$script_content.Add($(Write-output "`$inputXML =  '$xaml'"))

$script_content.Add($(Get-Content "$workingdir\scripts\main.ps1"))

if ($Debug) {
    Update-Progress "Writing debug files" 95
    $appXamlContent | Out-File -FilePath "$workingdir\xaml\inputApp.xaml" -Encoding ascii
    $tweaksXamlContent | Out-File -FilePath "$workingdir\xaml\inputTweaks.xaml" -Encoding ascii
    $featuresXamlContent | Out-File -FilePath "$workingdir\xaml\inputFeatures.xaml" -Encoding ascii
} else {
    Update-Progress "Removing temporary files" 99
    Remove-Item "$workingdir\xaml\inputApp.xaml" -ErrorAction SilentlyContinue
    Remove-Item "$workingdir\xaml\inputTweaks.xaml" -ErrorAction SilentlyContinue
    Remove-Item "$workingdir\xaml\inputFeatures.xaml" -ErrorAction SilentlyContinue
}

Set-Content -Path "$workingdir\$scriptname" -Value ($script_content -join "`r`n") -Encoding ascii
Write-Progress -Activity "Compiling" -Completed

Update-Progress -Activity "Validating" -StatusMessage "Checking winutil.ps1 Syntax" -Percent 0
try {
    $null = Get-Command -Syntax .\winutil.ps1
}
catch {
    Write-Warning "Syntax Validation for 'winutil.ps1' has failed"
    Write-Host "$($Error[0])" -ForegroundColor Red
}
Write-Progress -Activity "Validating" -Completed

if ($run) {
    $script = "& '$workingdir\$scriptname' $arg"

    $powershellcmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $powershellcmd }

    Start-Process $processCmd -ArgumentList "$powershellcmd -NoProfile -Command $script"

    break
}
