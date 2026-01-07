# Change Windows Terminal default: PowerShell 5 -> PowerShell 7

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

This will edit the config file of the Windows Terminal replacing PowerShell 5 with PowerShell 7 and installing PS7 if necessary

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Change Windows Terminal default: PowerShell 5 -> PowerShell 7",
  "Description": "This will edit the config file of the Windows Terminal replacing PowerShell 5 with PowerShell 7 and installing PS7 if necessary",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a009_",
  "InvokeScript": [
    "Invoke-WPFTweakPS7 -action \"PS7\""
  ],
  "UndoScript": [
    "Invoke-WPFTweakPS7 -action \"PS5\""
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Powershell7"
}
```

</details>

## Invoke Script

```powershell
Invoke-WPFTweakPS7 -action "PS7"

```
## Undo Script

```powershell
Invoke-WPFTweakPS7 -action "PS5"

```
## Function: Invoke-WPFTweakPS7

```powershell
function Invoke-WPFTweakPS7{
        <#
    .SYNOPSIS
        This will edit the config file of the Windows Terminal Replacing the Powershell 5 to Powershell 7 and install Powershell 7 if necessary
    .PARAMETER action
        PS7:           Configures Powershell 7 to be the default Terminal
        PS5:           Configures Powershell 5 to be the default Terminal
    #>
    param (
        [ValidateSet("PS7", "PS5")]
        [string]$action
    )

    switch ($action) {
        "PS7"{
            if (Test-Path -Path "$env:ProgramFiles\PowerShell\7") {
                Write-Host "Powershell 7 is already installed."
            } else {
                Write-Host "Installing Powershell 7..."
                Install-WinutilProgramWinget -Action Install -Programs @("Microsoft.PowerShell")
            }
            $targetTerminalName = "PowerShell"
        }
        "PS5"{
            $targetTerminalName = "Windows PowerShell"
        }
    }
    # Check if the Windows Terminal is installed and return if not (Prerequisite for the following code)
    if (-not (Get-Command "wt" -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Terminal not installed. Skipping Terminal preference"
        return
    }
    # Check if the Windows Terminal settings.json file exists and return if not (Prereqisite for the following code)
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path -Path $settingsPath)) {
        Write-Host "Windows Terminal Settings file not found at $settingsPath"
        return
    }

    Write-Host "Settings file found."
    $settingsContent = Get-Content -Path $settingsPath | ConvertFrom-Json
    $ps7Profile = $settingsContent.profiles.list | Where-Object { $_.name -eq $targetTerminalName }
    if ($ps7Profile) {
        $settingsContent.defaultProfile = $ps7Profile.guid
        $updatedSettings = $settingsContent | ConvertTo-Json -Depth 100
        Set-Content -Path $settingsPath -Value $updatedSettings
        Write-Host "Default profile updated to " -NoNewline
        Write-Host "$targetTerminalName " -ForegroundColor White -NoNewline
        Write-Host "using the name attribute."
    } else {
        Write-Host "No PowerShell 7 profile found in Windows Terminal settings using the name attribute."
    }
}

```
## Function: Install-WinutilProgramWinget

```powershell
Function Install-WinutilProgramWinget {
    <#
    .SYNOPSIS
    Runs the designated action on the provided programs using Winget

    .PARAMETER Programs
    A list of programs to process

    .PARAMETER action
    The action to perform on the programs, can be either 'Install' or 'Uninstall'

    .NOTES
    The triple quotes are required any time you need a " in a normal script block.
    The winget Return codes are documented here: https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-actionr/winget/returnCodes.md
    #>

    param(
        [Parameter(Mandatory, Position=0)]$Programs,

        [Parameter(Mandatory, Position=1)]
        [ValidateSet("Install", "Uninstall")]
        [String]$Action
    )

    Function Invoke-Winget {
    <#
    .SYNOPSIS
    Invokes the winget.exe with the provided arguments and return the exit code

    .PARAMETER wingetId
    The Id of the Program that Winget should Install/Uninstall

    .PARAMETER scope
    Determines the installation mode. Can be "user" or "machine" (For more info look at the winget documentation)

    .PARAMETER credential
    The PSCredential Object of the user that should be used to run winget

    .NOTES
    Invoke Winget uses the public variable $Action defined outside the function to determine if a Program should be installed or removed
    #>
        param (
            [string]$wingetId,
            [string]$scope = "",
            [PScredential]$credential = $null
        )

        $commonArguments = "--id $wingetId --silent"
        $arguments = if ($Action -eq "Install") {
            "install $commonArguments --accept-source-agreements --accept-package-agreements $(if ($scope) {" --scope $scope"})"
        } else {
            "uninstall $commonArguments"
        }

        $processParams = @{
            FilePath = "winget"
            ArgumentList = $arguments
            Wait = $true
            PassThru = $true
            NoNewWindow = $true
        }

        if ($credential) {
            $processParams.credential = $credential
        }

        return (Start-Process @processParams).ExitCode
    }

    Function Invoke-Install {
    <#
    .SYNOPSIS
    Contains the Install Logic and return code handling from winget

    .PARAMETER Program
    The Winget ID of the Program that should be installed
    #>
        param (
            [string]$Program
        )
        $status = Invoke-Winget -wingetId $Program
        if ($status -eq 0) {
            Write-Host "$($Program) installed successfully."
            return $true
        } elseif ($status -eq -1978335189) {
            Write-Host "$($Program) No applicable update found"
            return $true
        }

        Write-Host "Attempt installation of $($Program) with User scope"
        $status = Invoke-Winget -wingetId $Program -scope "user"
        if ($status -eq 0) {
            Write-Host "$($Program) installed successfully with User scope."
            return $true
        } elseif ($status -eq -1978335189) {
            Write-Host "$($Program) No applicable update found"
            return $true
        }

        $userChoice = [System.Windows.MessageBox]::Show("Do you want to attempt $($Program) installation with specific user credentials? Select 'Yes' to proceed or 'No' to skip.", "User credential Prompt", [System.Windows.MessageBoxButton]::YesNo)
        if ($userChoice -eq 'Yes') {
            $getcreds = Get-Credential
            $status = Invoke-Winget -wingetId $Program -credential $getcreds
            if ($status -eq 0) {
                Write-Host "$($Program) installed successfully with User prompt."
                return $true
            }
        } else {
            Write-Host "Skipping installation with specific user credentials."
        }

        Write-Host "Failed to install $($Program)."
        return $false
    }

    Function Invoke-Uninstall {
        <#
        .SYNOPSIS
        Contains the Uninstall Logic and return code handling from winget

        .PARAMETER Program
        The Winget ID of the Program that should be uninstalled
        #>
        param (
            [psobject]$Program
        )

        try {
            $status = Invoke-Winget -wingetId $Program
            if ($status -eq 0) {
                Write-Host "$($Program) uninstalled successfully."
                return $true
            } else {
                Write-Host "Failed to uninstall $($Program)."
                return $false
            }
        } catch {
            Write-Host "Failed to uninstall $($Program) due to an error: $_"
            return $false
        }
    }

    $count = $Programs.Count
    $failedPackages = @()

    Write-Host "==========================================="
    Write-Host "--    Configuring winget packages       ---"
    Write-Host "==========================================="

    for ($i = 0; $i -lt $count; $i++) {
        $Program = $Programs[$i]
        $result = $false
        Set-WinutilProgressBar -label "$Action $($Program)" -percent ($i / $count * 100)
        $sync.form.Dispatcher.Invoke([action]{ Set-WinutilTaskbaritem -value ($i / $count)})

        $result = switch ($Action) {
            "Install" {Invoke-Install -Program $Program}
            "Uninstall" {Invoke-Uninstall -Program $Program}
            default {throw "[Install-WinutilProgramWinget] Invalid action: $Action"}
        }

        if (-not $result) {
            $failedPackages += $Program
        }
    }

    Set-WinutilProgressBar -label "$($Action)ation done" -percent 100
    return $failedPackages
}

```
## Function: Set-WinutilProgressbar

```powershell
function Set-WinutilProgressbar{
    <#
    .SYNOPSIS
        This function is used to Update the Progress Bar displayed in the Winutil GUI.
        It will be automatically hidden if the user clicks something and no process is running
    .PARAMETER Label
        The Text to be overlayed onto the Progress Bar
    .PARAMETER PERCENT
        The percentage of the Progress Bar that should be filled (0-100)
    .PARAMETER Hide
        If provided, the Progress Bar and the label will be hidden
    #>
    param(
        [string]$Label,
        [ValidateRange(0,100)]
        [int]$Percent,
        $Hide
    )
    if ($hide) {
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Visibility = "Collapsed"})
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBar.Visibility = "Collapsed"})
    } else {
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Visibility = "Visible"})
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBar.Visibility = "Visible"})
    }
    $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Content.Text = $label})
    $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Content.ToolTip = $label})
    $sync.form.Dispatcher.Invoke([action]{ $sync.ProgressBar.Value = $percent})

}

```
## Function: Set-WinutilTaskbarItem

```powershell
function Set-WinutilTaskbaritem {
    <#

    .SYNOPSIS
        Modifies the Taskbaritem of the WPF Form

    .PARAMETER value
        Value can be between 0 and 1, 0 being no progress done yet and 1 being fully completed
        Value does not affect item without setting the state to 'Normal', 'Error' or 'Paused'
        Set-WinutilTaskbaritem -value 0.5

    .PARAMETER state
        State can be 'None' > No progress, 'Indeterminate' > inf. loading gray, 'Normal' > Gray, 'Error' > Red, 'Paused' > Yellow
        no value needed:
        - Set-WinutilTaskbaritem -state "None"
        - Set-WinutilTaskbaritem -state "Indeterminate"
        value needed:
        - Set-WinutilTaskbaritem -state "Error"
        - Set-WinutilTaskbaritem -state "Normal"
        - Set-WinutilTaskbaritem -state "Paused"

    .PARAMETER overlay
        Overlay icon to display on the taskbar item, there are the presets 'None', 'logo' and 'checkmark' or you can specify a path/link to an image file.
        CTT logo preset:
        - Set-WinutilTaskbaritem -overlay "logo"
        Checkmark preset:
        - Set-WinutilTaskbaritem -overlay "checkmark"
        Warning preset:
        - Set-WinutilTaskbaritem -overlay "warning"
        No overlay:
        - Set-WinutilTaskbaritem -overlay "None"
        Custom icon (needs to be supported by WPF):
        - Set-WinutilTaskbaritem -overlay "C:\path\to\icon.png"

    .PARAMETER description
        Description to display on the taskbar item preview
        Set-WinutilTaskbaritem -description "This is a description"
    #>
    param (
        [string]$state,
        [double]$value,
        [string]$overlay,
        [string]$description
    )

    if ($value) {
        $sync["Form"].taskbarItemInfo.ProgressValue = $value
    }

    if ($state) {
        switch ($state) {
            'None' { $sync["Form"].taskbarItemInfo.ProgressState = "None" }
            'Indeterminate' { $sync["Form"].taskbarItemInfo.ProgressState = "Indeterminate" }
            'Normal' { $sync["Form"].taskbarItemInfo.ProgressState = "Normal" }
            'Error' { $sync["Form"].taskbarItemInfo.ProgressState = "Error" }
            'Paused' { $sync["Form"].taskbarItemInfo.ProgressState = "Paused" }
            default { throw "[Set-WinutilTaskbarItem] Invalid state" }
        }
    }

    if ($overlay) {
        switch ($overlay) {
            'logo' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\Winutil\cttlogo.png"
            }
            'checkmark' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\Winutil\checkmark.png"
            }
            'warning' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\Winutil\warning.png"
            }
            'None' {
                $sync["Form"].taskbarItemInfo.Overlay = $null
            }
            default {
                if (Test-Path $overlay) {
                    $sync["Form"].taskbarItemInfo.Overlay = $overlay
                }
            }
        }
    }

    if ($description) {
        $sync["Form"].taskbarItemInfo.Description = $description
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

