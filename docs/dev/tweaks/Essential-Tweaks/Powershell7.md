# Change Windows Terminal default: PowerShell 5 -> PowerShell 7

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

This will edit the config file of the Windows Terminal replacing PowerShell 5 with PowerShell 7 and installing PS7 if necessary

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Change Windows Terminal default: PowerShell 5 -\u003e PowerShell 7",
    "Description":  "This will edit the config file of the Windows Terminal replacing PowerShell 5 with PowerShell 7 and installing PS7 if necessary",
    "category":  "Essential Tweaks",
    "panel":  "1",
    "Order":  "a009_",
    "InvokeScript":  [
                         "Invoke-WPFTweakPS7 -action \"PS7\""
                     ],
    "UndoScript":  [
                       "Invoke-WPFTweakPS7 -action \"PS5\""
                   ]
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
                Install-WinUtilProgramWinget -ProgramsToInstall @(@{"winget"="Microsoft.PowerShell"})
            }
            $targetTerminalName = "PowerShell"
        }
        "PS5"{
            $targetTerminalName = "Windows PowerShell"
        }
    }
    # Check if the Windows Terminal is installed and return if not (Prerequisite for the following code)
    if (-not (Get-Command "wt" -ErrorAction SilentlyContinue)){
        Write-Host "Windows Terminal not installed. Skipping Terminal preference"
        return
    }
    # Check if the Windows Terminal settings.json file exists and return if not (Prereqisite for the following code)
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path -Path $settingsPath)){
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

## Function: Install-WinUtilProgramWinget
```powershell
Function Install-WinUtilProgramWinget {

    <#
    .SYNOPSIS
    Manages the provided programs using Winget

    .PARAMETER ProgramsToInstall
    A list of programs to manage

    .PARAMETER manage
    The action to perform on the programs, can be either 'Installing' or 'Uninstalling'

    .NOTES
    The triple quotes are required any time you need a " in a normal script block.
    The winget Return codes are documented here: https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md
    #>

    param(
        [Parameter(Mandatory, Position=0)]
        [PsCustomObject]$ProgramsToInstall,

        [Parameter(Position=1)]
        [String]$manage = "Installing"
    )

    $count = $ProgramsToInstall.Count

    Write-Progress -Activity "$manage Applications" -Status "Starting" -PercentComplete 0
    Write-Host "==========================================="
    Write-Host "--    Configuring winget packages       ---"
    Write-Host "==========================================="
    for ($i = 0; $i -lt $count; $i++) {
        $Program = $ProgramsToInstall[$i]
        $failedPackages = @()
        Write-Progress -Activity "$manage Applications" -Status "$manage $($Program.winget) $($i + 1) of $count" -PercentComplete $((($i + 1)/$count) * 100)
        if($manage -eq "Installing") {
            # Install package via ID, if it fails try again with different scope and then with an unelevated prompt.
            # Since Install-WinGetPackage might not be directly available, we use winget install command as a workaround.
            # Winget, not all installers honor any of the following: System-wide, User Installs, or Unelevated Prompt OR Silent Install Mode.
            # This is up to the individual package maintainers to enable these options. Aka. not as clean as Linux Package Managers.
            Write-Host "Starting install of $($Program.winget) with winget."
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru -NoNewWindow).ExitCode
                if($status -eq 0) {
                    Write-Host "$($Program.winget) installed successfully."
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
                    continue
                }
                if ($status -eq -1978335189) {
                    Write-Host "$($Program.winget) No applicable update found"
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
                    continue
                }
                Write-Host "Attempt with User scope"
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --scope user --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru -NoNewWindow).ExitCode
                if($status -eq 0) {
                    Write-Host "$($Program.winget) installed successfully with User scope."
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
                    continue
                }
                if ($status -eq -1978335189) {
                    Write-Host "$($Program.winget) No applicable update found"
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
                    continue
                }
                Write-Host "Attempt with User prompt"
                $userChoice = [System.Windows.MessageBox]::Show("Do you want to attempt $($Program.winget) installation with specific user credentials? Select 'Yes' to proceed or 'No' to skip.", "User Credential Prompt", [System.Windows.MessageBoxButton]::YesNo)
                if ($userChoice -eq 'Yes') {
                    $getcreds = Get-Credential
                    $process = Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --silent --accept-source-agreements --accept-package-agreements" -Credential $getcreds -PassThru -NoNewWindow
                    Wait-Process -Id $process.Id
                    $status = $process.ExitCode
                } else {
                    Write-Host "Skipping installation with specific user credentials."
                }
                if($status -eq 0) {
                    Write-Host "$($Program.winget) installed successfully with User prompt."
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
                    continue
                }
                if ($status -eq -1978335189) {
                    Write-Host "$($Program.winget) No applicable update found"
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
                    continue
                }
            } catch {
                Write-Host "Failed to install $($Program.winget). With winget"
                $failedPackages += $Program
                $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" -value ($x/$count) })
            }
        }
        elseif($manage -eq "Uninstalling") {
            # Uninstall package via ID using winget directly.
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "uninstall --id $($Program.winget) --silent" -Wait -PassThru -NoNewWindow).ExitCode
                if($status -ne 0) {
                    Write-Host "Failed to uninstall $($Program.winget)."
                    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" })
                } else {
                    Write-Host "$($Program.winget) uninstalled successfully."
                    $failedPackages += $Program
                }
            } catch {
                Write-Host "Failed to uninstall $($Program.winget) due to an error: $_"
                $failedPackages += $Program
                $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Error" })
            }
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($x/$count) })
        }
        else {
            throw "[Install-WinUtilProgramWinget] Invalid Value for Parameter 'manage', Provided Value is: $manage"
        }
    }
    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed
    return $failedPackages;
}

```

## Function: Set-WinUtilTaskbarItem
```powershell
function Set-WinUtilTaskbaritem {
    <#

    .SYNOPSIS
        Modifies the Taskbaritem of the WPF Form

    .PARAMETER value
        Value can be between 0 and 1, 0 being no progress done yet and 1 being fully completed
        Value does not affect item without setting the state to 'Normal', 'Error' or 'Paused'
        Set-WinUtilTaskbaritem -value 0.5

    .PARAMETER state
        State can be 'None' > No progress, 'Indeterminate' > inf. loading gray, 'Normal' > Gray, 'Error' > Red, 'Paused' > Yellow
        no value needed:
        - Set-WinUtilTaskbaritem -state "None"
        - Set-WinUtilTaskbaritem -state "Indeterminate"
        value needed:
        - Set-WinUtilTaskbaritem -state "Error"
        - Set-WinUtilTaskbaritem -state "Normal"
        - Set-WinUtilTaskbaritem -state "Paused"

    .PARAMETER overlay
        Overlay icon to display on the taskbar item, there are the presets 'None', 'logo' and 'checkmark' or you can specify a path/link to an image file.
        CTT logo preset:
        - Set-WinUtilTaskbaritem -overlay "logo"
        Checkmark preset:
        - Set-WinUtilTaskbaritem -overlay "checkmark"
        Warning preset:
        - Set-WinUtilTaskbaritem -overlay "warning"
        No overlay:
        - Set-WinUtilTaskbaritem -overlay "None"
        Custom icon (needs to be supported by WPF):
        - Set-WinUtilTaskbaritem -overlay "C:\path\to\icon.png"

    .PARAMETER description
        Description to display on the taskbar item preview
        Set-WinUtilTaskbaritem -description "This is a description"
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
            default { throw "[Set-WinUtilTaskbarItem] Invalid state" }
        }
    }

    if ($overlay) {
        switch ($overlay) {
            'logo' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\winutil\cttlogo.png"
            }
            'checkmark' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\winutil\checkmark.png"
            }
            'warning' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\winutil\warning.png"
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

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

