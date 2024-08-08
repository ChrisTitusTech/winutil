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
    # Call the choice executable to ask the user if they want to elevate
    $choiceCmd = "$env:SystemRoot\System32\choice.exe /c YN /t 60 /D Y /N /M ""Would you like to restart as Administrator? (Y/N)"""
    Invoke-Expression $choiceCmd
    $choiceResult = $?
    if ($choiceResult) {
        # Check if the build number of the operating system is 6000 or higher
        # (Windows Vista/Server 2008 and later versions have build numbers of 6000 or higher)
        if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
            # Re-run the current script with all the original arguments as admin
            $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
            Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
            exit
        }
    }
    exit
}

# Set PowerShell window title
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Admin)"
clear-host
