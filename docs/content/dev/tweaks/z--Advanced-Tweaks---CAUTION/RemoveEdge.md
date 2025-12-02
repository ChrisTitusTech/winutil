# Remove Microsoft Edge

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Removes MS Edge when it gets reinstalled by updates. Credit: Techie Jack

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Remove Microsoft Edge",
  "Description": "Removes MS Edge when it gets reinstalled by updates. Credit: Techie Jack",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a029_",
  "InvokeScript": [
    "
         Uninstall-WinutilEdgeBrowser
        "
  ],
  "UndoScript": [
    "
      Write-Host \"Install Microsoft Edge\"
      Start-Process -FilePath winget -ArgumentList \"install --force -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge \" -NoNewWindow -Wait
      "
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/RemoveEdge"
}
```

</details>

## Invoke Script

```powershell

         Uninstall-WinutilEdgeBrowser


```
## Undo Script

```powershell

      Write-Host "Install Microsoft Edge"
      Start-Process -FilePath winget -ArgumentList "install --force -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge " -NoNewWindow -Wait


```
## Function: Uninstall-WinutilEdgeBrowser

```powershell
Function Uninstall-WinutilEdgeBrowser {

    <#

    .SYNOPSIS
        This will uninstall edge by changing the region to Ireland and uninstalling edge the changing it back

    #>

$msedgeProcess = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
$widgetsProcess = Get-Process -Name "widgets" -ErrorAction SilentlyContinue
# Checking if Microsoft Edge is running
if ($msedgeProcess) {
    Stop-Process -Name "msedge" -Force
} else {
    Write-Output "msedge process is not running."
}
# Checking if Widgets is running
if ($widgetsProcess) {
    Stop-Process -Name "widgets" -Force
} else {
    Write-Output "widgets process is not running."
}

function Uninstall-Process {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $originalNation = [microsoft.win32.registry]::GetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', [Microsoft.Win32.RegistryValueKind]::String)

    # Set Nation to 84 (France) temporarily
    [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', 68, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null

    # credits to he3als for the Acl commands
    $fileName = "IntegratedServicesRegionPolicySet.json"
    $pathISRPS = [Environment]::SystemDirectory + "\" + $fileName
    $aclISRPS = Get-Acl -Path $pathISRPS
    $aclISRPSBackup = [System.Security.AccessControl.FileSecurity]::new()
    $aclISRPSBackup.SetSecurityDescriptorSddlForm($acl.Sddl)
    if (Test-Path -Path $pathISRPS) {
        try {
            $admin = [System.Security.Principal.NTAccount]$(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value

            $aclISRPS.SetOwner($admin)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admin, 'FullControl', 'Allow')
            $aclISRPS.AddAccessRule($rule)
            Set-Acl -Path $pathISRPS -AclObject $aclISRPS

            Rename-Item -Path $pathISRPS -NewName ($fileName + '.bak') -Force
        }
        catch {
            Write-Error "[$Mode] Failed to set owner for $pathISRPS"
        }
    }

    $baseKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
    $registryPath = $baseKey + '\ClientState\' + $Key

    if (!(Test-Path -Path $registryPath)) {
        Write-Host "[$Mode] Registry key not found: $registryPath"
        return
    }

    Remove-ItemProperty -Path $registryPath -Name "experiment_control_labels" -ErrorAction SilentlyContinue | Out-Null

    $uninstallString = (Get-ItemProperty -Path $registryPath).UninstallString
    $uninstallArguments = (Get-ItemProperty -Path $registryPath).UninstallArguments

    if ([string]::IsNullOrEmpty($uninstallString) -or [string]::IsNullOrEmpty($uninstallArguments)) {
        Write-Host "[$Mode] Cannot find uninstall methods for $Mode"
        return
    }

    $uninstallArguments += " --force-uninstall --delete-profile"

    # $uninstallCommand = "`"$uninstallString`"" + $uninstallArguments
    if (!(Test-Path -Path $uninstallString)) {
        Write-Host "[$Mode] setup.exe not found at: $uninstallString"
        return
    }
    Start-Process -FilePath $uninstallString -ArgumentList $uninstallArguments -Wait -NoNewWindow -Verbose

    # Restore Acl
    if (Test-Path -Path ($pathISRPS + '.bak')) {
        Rename-Item -Path ($pathISRPS + '.bak') -NewName $fileName -Force
        Set-Acl -Path $pathISRPS -AclObject $aclISRPSBackup
    }

    # Restore Nation
    [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', $originalNation, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null

    if ((Get-ItemProperty -Path $baseKey).IsEdgeStableUninstalled -eq 1) {
        Write-Host "[$Mode] Edge Stable has been successfully uninstalled"
    }
}

function Uninstall-Edge {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

    [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev", "AllowUninstall", 1, [Microsoft.Win32.RegistryValueKind]::DWord) | Out-Null

    Uninstall-Process -Key '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'

    @( "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
       "$env:PUBLIC\Desktop",
       "$env:USERPROFILE\Desktop" ) | ForEach-Object {
        $shortcutPath = Join-Path -Path $_ -ChildPath "Microsoft Edge.lnk"
        if (Test-Path -Path $shortcutPath) {
            Remove-Item -Path $shortcutPath -Force
        }
    }

}

function Uninstall-WebView {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

    # Force to use system-wide WebView2
    # [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder", "*", "%%SystemRoot%%\System32\Microsoft-Edge-WebView")

    Uninstall-Process -Key '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
}

function Uninstall-EdgeUpdate {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

    $registryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
    if (!(Test-Path -Path $registryPath)) {
        Write-Host "Registry key not found: $registryPath"
        return
    }
    $uninstallCmdLine = (Get-ItemProperty -Path $registryPath).UninstallCmdLine

    if ([string]::IsNullOrEmpty($uninstallCmdLine)) {
        Write-Host "Cannot find uninstall methods for $Mode"
        return
    }

    Write-Output "Uninstalling: $uninstallCmdLine"
    Start-Process cmd.exe "/c $uninstallCmdLine" -WindowStyle Hidden -Wait
}

Uninstall-Edge
    # "WebView" { Uninstall-WebView }
    # "EdgeUpdate" { Uninstall-EdgeUpdate }




}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

