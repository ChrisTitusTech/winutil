<#
.NOTES
    Author         : Chris Titus @christitustech
    Runspace Author: @DeveloperDurp
    GitHub         : https://github.com/ChrisTitusTech
    Version        : #{replaceme}
#>

param (
    [string]$Config,
    [switch]$Noui,
    [switch]$Offline
)

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

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Winutil needs to be ran as Administrator. Attempting to relaunch."

    $argList = @(
        if ($Config) { "-Config $Config" }
        if ($Preset) { "-Preset $Preset" }
        if ($Offline) { "-Offline" }
        if ($Noui) { "-Noui" }
    ) -join " "

    $script = if ($PSCommandPath) {
        "$PSCommandPath $argList"
    } else {
        "& ([ScriptBlock]::Create((irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1))) $argList"
    }

    $powershell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }

    if (Get-Command -Name wt -ErrorAction SilentlyContinue) {
        Start-Process wt.exe -ArgumentList "$powershellCmd -Command $script" -Verb RunAs
    } else {
        Start-Process $powershell -ArgumentList "-Command $script" -Verb RunAs
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
