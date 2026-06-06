<#
.NOTES
    Author         : Chris Titus @christitustech
    Runspace Author: @DeveloperDurp
    GitHub         : https://github.com/ChrisTitusTech
    Version        : #{replaceme}
#>

param (
    [string]$Config,
    [string]$Preset,
    [switch]$Noui,
    [switch]$Offline
)

if ($Preset -and $Preset -notin @('Standard', 'Minimal', 'Advanced')) {
    throw "Invalid Preset '$Preset'. Valid values are: Standard, Minimal, Advanced."
}

if ($Config) {
    $PARAM_CONFIG = $Config
}

$PARAM_NOUI = $false
if ($Noui) {
    $PARAM_NOUI = $true
}

$PARAM_OFFLINE = $false
if ($Offline) {
    $PARAM_OFFLINE = $true
}

if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Host "WinUtil is unable to run on your system, powershell execution is restricted by security policies" -ForegroundColor Red
    return
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Winutil needs to be run as Administrator. Attempting to relaunch."

    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $elevatedArgs = @('-ExecutionPolicy', 'Bypass', '-NoProfile')

    if ($PSCommandPath) {
        $elevatedArgs += @('-File', $PSCommandPath)
        $PSBoundParameters.GetEnumerator() | ForEach-Object {
            if ($_.Value -is [switch] -and $_.Value) {
                $elevatedArgs += "-$($_.Key)"
            } elseif ($_.Value -is [array]) {
                $elevatedArgs += "-$($_.Key)"
                $elevatedArgs += ($_.Value -join ',')
            } elseif ($null -ne $_.Value -and -not ($_.Value -is [switch])) {
                $elevatedArgs += "-$($_.Key)"
                $elevatedArgs += $_.Value.ToString()
            }
        }
        $launchTarget = $powershellCmd
    } else {
        $bootstrapScript = Join-Path $env:TEMP "winutil-bootstrap.ps1"
        Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1" -OutFile $bootstrapScript
        $elevatedArgs += @('-File', $bootstrapScript)
        $PSBoundParameters.GetEnumerator() | ForEach-Object {
            if ($_.Value -is [switch] -and $_.Value) {
                $elevatedArgs += "-$($_.Key)"
            } elseif ($_.Value -is [array]) {
                $elevatedArgs += "-$($_.Key)"
                $elevatedArgs += ($_.Value -join ',')
            } elseif ($null -ne $_.Value -and -not ($_.Value -is [switch])) {
                $elevatedArgs += "-$($_.Key)"
                $elevatedArgs += $_.Value.ToString()
            }
        }
        $launchTarget = $powershellCmd
    }

    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $launchTarget }

    if ($processCmd -eq "wt.exe") {
        Start-Process -FilePath $processCmd -ArgumentList (@($launchTarget) + $elevatedArgs) -Verb RunAs
    } else {
        Start-Process -FilePath $launchTarget -ArgumentList $elevatedArgs -Verb RunAs
    }

    break
}

# Load DLLs
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $PSScriptRoot
$sync.version = "#{replaceme}"
$sync.configs = @{}
$sync.Buttons = [System.Collections.Generic.List[PSObject]]::new()
$sync.preferences = @{}
$sync.ProcessRunning = $false
$sync.ActiveToggleJobs = 0
$sync.selectedApps = [System.Collections.Generic.List[string]]::new()
$sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
$sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
$sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()
$sync.currentTab = "Install"
$sync.selectedAppsStackPanel
$sync.selectedAppsPopup

$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Set the path for the winutil directory
$winutildir = "$env:LocalAppData\winutil"
New-Item $winutildir -ItemType Directory -Force | Out-Null

$logdir = "$winutildir\logs"
New-Item $logdir -ItemType Directory -Force | Out-Null
Start-Transcript -Path "$logdir\winutil_$dateTime.log" -Append -NoClobber | Out-Null

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = "WinUtil (Admin)"
clear-host
