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

# If script isn't running as admin, show error message and quit
if (([Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -ne "S-1-5-32-544") {
    Write-Host "===========================================" -ForegroundColor Red
    Write-Host "-- Scripts must be run as Administrator ---" -ForegroundColor Red
    Write-Host "-- Right-Click Start -> Terminal(Admin) ---" -ForegroundColor Red
    Write-Host "===========================================" -ForegroundColor Red
    $choiceCmd = "$env:SystemRoot\System32\choice.exe /c YN /t 60 /D Y /N /M ""Would you like to restart as Administrator?"""
    Invoke-Expression $choiceCmd
    $choiceResult = $?
    if ($choiceResult) {
        if (-not (Get-Command fltmc -ErrorAction SilentlyContinue)) {
            try {
                # Attempt to restart the script with elevated privileges
                Start-Process PowerShell -ArgumentList "Start-Process PowerShell -ArgumentList '-File ""$PSCommandPath""' -Verb RunAs" -NoNewWindow
            } catch {
                # If elevation fails, pause and exit with error code 1
                Read-Host "Press Enter to continue..." | Out-Null
                exit 1
            }
            exit
        }
    }
    exit
}

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Admin)"
clear-host
