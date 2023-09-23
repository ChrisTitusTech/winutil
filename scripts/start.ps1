<#
.NOTES
    Author         : Chris Titus @christitustech
    Runspace Author: @DeveloperDurp
    GitHub         : https://github.com/ChrisTitusTech
    Version        : #{replaceme}
#>
# TODO: add support for confrim and whatif
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
  [Parameter(Mandatory=$false)]
  [switch]$ListTweaks,
  [Parameter(Mandatory=$false)]
  [string[]]$Tweaks,
  [Parameter(Mandatory=$false)]
  [switch]$Undo

)

Start-Transcript $ENV:TEMP\Winutil.log -Append

#Load DLLs
Add-Type -AssemblyName System.Windows.Forms

# variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $PSScriptRoot
$sync.version = "#{replaceme}"
$sync.configs = @{}
$sync.ProcessRunning = $false

# TODO: add support for confrim and whatif
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "Winutil needs to be run as Administrator. Attempting to relaunch."
    Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "iwr -useb https://christitus.com/win | iex"
    break
}
