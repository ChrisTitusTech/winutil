<#
.NOTES
    Author         : Chris Titus @christitustech
    Runspace Author: @DeveloperDurp
    GitHub         : https://github.com/ChrisTitusTech
    Version        : #{replaceme}
#>
param (
    [switch]$Debug,
    [string]$Config,
    [switch]$Run
)

# Set DebugPreference based on the -Debug switch
if ($Debug) {
    $DebugPreference = "Continue"
}

if ($Config) {
    $PARAM_CONFIG = $Config
}

$PARAM_RUN = $false
# Handle the -Run switch
if ($Run) {
    Write-Host "Running config file tasks..."
    $PARAM_RUN = $true
}

if (!(Test-Path -Path $ENV:TEMP)) {
    New-Item -ItemType Directory -Force -Path $ENV:TEMP
}

Start-Transcript $ENV:TEMP\Winutil.log -Append

# Load DLLs
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $PSScriptRoot
$sync.version = "#{replaceme}"
$sync.configs = @{}
$sync.ProcessRunning = $false

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Winutil needs to be run as Administrator. Attempting to relaunch."

    $script = if (Test-Path "$PSScriptRoot\winutil.ps1") {
        "$PSScriptRoot\winutil.ps1"
    } else {
        "irm christitus.com/win | iex"
    }
    $powershellcmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        "pwsh.exe"
    } else {
        "powershell.exe"
    }

    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        "wt.exe"
    } else {
        $powershellcmd
    }
    Start-Process $processCmd -ArgumentList "$powershellcmd -ExecutionPolicy Bypass -NoProfile -Command $script" -Verb RunAs

    break
}

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Admin)"
clear-host
