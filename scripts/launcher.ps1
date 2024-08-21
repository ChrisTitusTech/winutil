# Copyright (c) Chris Titus.
# Licensed under the MIT License.
<#
.Synopsis
    Launch winutil with administrative privileges.
.DESCRIPTION
    This script is used to launch winutil with administrative privileges.
    It is intended to be deployed at https://christitus.com/win.

    This script will check if the current user is an Administrator.
    If the current user is an Administrator, it will run winutil in the current session.
    If not, it will run winutil with elevated privileges in a new session.
.Parameter Preview
    Launch the preview version of winutil.
.Parameter NoExit
    Do not exit the newly spawned powershell after running the script. (for-debugging purposes)
.EXAMPLE
    Launch the latest release of winutil.
    .\launcher.ps1
.EXAMPLE
    Launch the latest release of winutil. (one-liner)
    Invoke-Expression "& { $(Invoke-RestMethod 'https://christitus.com/win') }"
    iex "& { $(iwr 'https://christitus.com/win') }"
.EXAMPLE
    Launch the latest preview release of winutil.
    .\launcher.ps1 -preview
.EXAMPLE
    Launch the latest preview release of winutil. (one-liner)
    Invoke-Expression "& { $(Invoke-RestMethod 'https://christitus.com/win') } -preview"
    iex "& { $(iwr 'https://christitus.com/win') } -preview"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch] $Preview,
    
    [Parameter()]
    [switch] $NoExit
)

& {
    $ErrorActionPreference = "Stop"

    $IsAdmin = [bool](
        [Security.Principal.WindowsPrincipal](
            [Security.Principal.WindowsIdentity]::GetCurrent()
        )
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    # Enable TLSv1.2 for compatibility with older clients for current session
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Function to redirect to the latest pre-release version
    function Get-Latest-PreRelease-Url {
        $repo = 'ChrisTitusTech/winutil'

        $latestPreRelease = $null

        try {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases"
            $latestRelease = $releases | Where-Object {$_.prerelease -eq $true} | Select-Object -First 1
            $latestPreRelease = $latestRelease.tag_name
        } catch {
            Write-Host "Error fetching release data: $_" -ForegroundColor Red
            $latestPreRelease = $latestRelease.tag_name
        }

        if ($latestPreRelease) {
            return "https://github.com/$repo/releases/download/$latestPreRelease/winutil.ps1"
        } else {
            Write-Host 'Unable to determine latest pre-release version.' -ForegroundColor Red
            Write-Host "Using latest Stable Release"
            return "https://github.com/$repo/releases/latest/download/winutil.ps1"
        }
    }

    $url = if (-not $Preview) {
        # This must be pointing to the latest stable release (Chris-Hosted)
        # FIXME: change me to the below url and host me here
        "https://christitus.com/win"
        # "https://christitus.com/win/stable"
    } else {
        # This must be pointing to the latest pre-release or the release (GitHub releases)
        Get-Latest-PreRelease-Url
    }

    if ($IsAdmin) {
        # If running as Administrator, run in the current session
        & {
            # Using iwr to show download progress
            # TODO(psyirius): Check the output of Invoke-WebRequest and handle errors
            Invoke-WebRequest $url | Invoke-Expression
        }
        
        exit
    }

    #============================================================================
    # If not running as Administrator, run the script with elevated privileges
    #============================================================================

    # Use the modern 'PowerShell' if available, otherwise use 'Windows PowerShell'
    $PwshExecutable = if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
        "pwsh.exe"
    }
    else {
        "powershell.exe"
    }

    # Using iwr to show download progress
    # TODO(psyirius): Check the output of Invoke-WebRequest and handle errors
    $PwshCommand = "iwr '$url' | iex"

    # Elevate the script
    $PwshArgList = @(
        "-NoLogo",                                  # Don't print PowerShell header in CLI
        "-NoProfile",                               # Don't load PowerShell profile
        "-Command", $PwshCommand                    # Command to execute
    )

    if ($NoExit) {
        $PwshArgList = @(
            "-NoExit"                               # Don't exit after running the command
        ) + $PwshArgList
    }

    $PwshArgList = $PwshArgList | ForEach-Object { "`"$_`"" }

    $WorkingDirectory = Get-Location

    $PwshExecutable = if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
        "pwsh.exe"
    }
    else {
        "powershell.exe"
    }

    $ProcessParameters = @{
        FilePath            = $PwshExecutable;
        ArgumentList        = $PwshArgList;
        WorkingDirectory    = $WorkingDirectory;
        Verb                = 'RunAs';
        PassThru            = $true;
    }

    # Use 'wt' if available
    if (Get-Command "wt" -ErrorAction SilentlyContinue) {
        $WtArgList = @(
            "new-tab",
            $ProcessParameters.FilePath
        ) + $PwshArgList

        $ProcessParameters.FilePath = "wt.exe"
        $ProcessParameters.ArgumentList = $WtArgList
    }

    $process = $null
    try {
        $process = Start-Process @ProcessParameters
    }
    catch {
        $exception = $_.Exception
    
        # Optional: Check for specific error messages or types
        if ($exception.Message -like "*The operation was canceled by the user*") {
            Write-Host "===========================================" -Foregroundcolor Red
            Write-Host "---- This must be run as Administrator ----" -Foregroundcolor Red
            Write-Host "------ Click 'Yes' in the UAC Prompt ------" -Foregroundcolor Red
            Write-Host "------------------ (OR) -------------------" -Foregroundcolor Red
            Write-Host "-- Right-Click Start -> Terminal(Admin) ---" -Foregroundcolor Red
            Write-Host "===========================================" -Foregroundcolor Red
        }
        else {
            $ErrorMessage = @(
                "An unexpected error occurred:",
                ($exception.Message -split ":" | Select-Object -Index 1).Trim()
            ) -join "`n"

            Write-Host $ErrorMessage -Foregroundcolor Red

            $process.Kill()
        }
    }
    finally {
        exit
    }
}