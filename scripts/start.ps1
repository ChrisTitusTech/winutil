<#
.NOTES
    Author          : Chris Titus @christitustech
    Runspace Author : @DeveloperDurp
    GitHub          : https://github.com/ChrisTitusTech
    Version         : #{replaceme}
#>

# Define the arguments for the WinUtil script
param (
    [switch]$Debug,
    [string]$Config,
    [switch]$Run
)

# Set DebugPreference based on the -Debug switch
if ($Debug) {
    $DebugPreference = "Continue"
}

# Handle the -Config parameter
if ($Config) {
    $PARAM_CONFIG = $Config
}

# Handle the -Run switch
$PARAM_RUN = $false
if ($Run) {
    Write-Host "Running config file tasks..."
    $PARAM_RUN = $true
}

# Load DLLs
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $PSScriptRoot
$sync.version = "#{replaceme}"
$sync.configs = @{}
$sync.ProcessRunning = $false

# Store elevation status of the process
$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Initialize the arguments list array
$argsList = @()

# Add the passed parameters to $argsList
$PSBoundParameters.GetEnumerator() | ForEach-Object {
    $argsList += if ($_.Value -is [switch] -and $_.Value) {
        "-$($_.Key)"
    } elseif ($_.Value) {
        "-$($_.Key) `"$($_.Value)`""
    }
}

# Set the download URL for the latest release
$downloadURL = "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"

# Download the WinUtil script to '$env:TEMP'
try {
    Write-Host "Downloading the latest stable WinUtil version..." -ForegroundColor Green
    Invoke-RestMethod $downloadURL -OutFile "$env:TEMP\winutil.ps1"
} catch {
    Write-Host "Error downloading WinUtil: $_" -ForegroundColor Red
    break
}

# Setup the commands used to launch the script
$powershellCmd = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
$processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $powershellCmd }

# Setup the script's launch arguments
$launchArguments = "-ExecutionPolicy Bypass -NoProfile -File `"$env:TEMP\winutil.ps1`" $argsList"
if ($processCmd -ne $powershellCmd) {
    $launchArguments = "$powershellCmd $launchArguments"
}

# Store the script's directory in $ScriptDirectory
# Note: This is not used with -WorkingDirectory but
# is used in the PowerShell instance's window title.
if ($MyInvocation.MyCommand.Path) {
    $ScriptDirectory = "$(Split-Path $MyInvocation.MyCommand.Path)"
} elseif ($PSScriptRoot) {
    $ScriptDirectory = "$($PSScriptRoot)"
} else {
    $ScriptDirectory = "$($PWD)"
}

# Create the base titles used for naming the instance
$FallbackWindowTitle = "$ScriptDirectory\winutil.ps1"
$BaseWindowTitle = if ($MyInvocation.MyCommand.Path) {
    $MyInvocation.MyCommand.Path
} else {
    $MyInvocation.MyCommand.Definition
}

# Append (User) or (Admin) prefix to the window title
try {
    $Host.UI.RawUI.WindowTitle = if ($isElevated) {
        $BaseWindowTitle + " (Admin)"
    } else {
        $BaseWindowTitle + " (User)"
    }
} catch {
    $Host.UI.RawUI.WindowTitle = if ($isElevated) {
        "$FallbackWindowTitle (Admin)"
    } else {
        "$FallbackWindowTitle (User)"
    }
}

# Relaunch the script as administrator if necessary
try {
    if (!$isElevated) {
        Write-Host "WinUtil is not running as administrator. Relaunching..." -ForegroundColor DarkCyan
        Start-Process $processCmd -ArgumentList $launchArguments -Verb RunAs
        break
    } else {
        Write-Host "Running the latest stable version of WinUtil as admin." -ForegroundColor DarkCyan
    }
} catch {
    Write-Host "Error launching WinUtil: $_" -ForegroundColor Red
    break
}

# Start WinUtil transcript logging
$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logdir = "$env:localappdata\winutil\logs"
[System.IO.Directory]::CreateDirectory("$logdir") | Out-Null
Start-Transcript -Path "$logdir\winutil_$dateTime.log" -Append -NoClobber | Out-Null