# Block Razer Software Installs

Last Updated: 2024-10-01


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Blocks ALL Razer Software installations. The hardware works fine without any software.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Block Razer Software Installs",
  "Description": "Blocks ALL Razer Software installations. The hardware works fine without any software.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a031_",
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DriverSearching",
      "Name": "SearchOrderConfig",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Device Installer",
      "Name": "DisableCoInstallers",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "
          $RazerPath = \"C:\\Windows\\Installer\\Razer\"
          Remove-Item $RazerPath -Recurse -Force
          New-Item -Path \"C:\\Windows\\Installer\\\" -Name \"Razer\" -ItemType \"directory\"
          $Acl = Get-Acl $RazerPath
          $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(\"NT AUTHORITY\\SYSTEM\",\"Write\",\"ContainerInherit,ObjectInherit\",\"None\",\"Deny\")
          $Acl.SetAccessRule($Ar)
          Set-Acl $RazerPath $Acl
      "
  ],
  "UndoScript": [
    "
          $RazerPath = \"C:\\Windows\\Installer\\Razer\"
          Remove-Item $RazerPath -Recurse -Force
          New-Item -Path \"C:\\Windows\\Installer\\\" -Name \"Razer\" -ItemType \"directory\"
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/RazerBlock"
}
```

</details>

## Invoke Script

```powershell

          $RazerPath = "C:\Windows\Installer\Razer"
          Remove-Item $RazerPath -Recurse -Force
          New-Item -Path "C:\Windows\Installer\" -Name "Razer" -ItemType "directory"
          $Acl = Get-Acl $RazerPath
          $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","Write","ContainerInherit,ObjectInherit","None","Deny")
          $Acl.SetAccessRule($Ar)
          Set-Acl $RazerPath $Acl


```
## Undo Script

```powershell

          $RazerPath = "C:\Windows\Installer\Razer"
          Remove-Item $RazerPath -Recurse -Force
          New-Item -Path "C:\Windows\Installer\" -Name "Razer" -ItemType "directory"


```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: SearchOrderConfig

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: DisableCoInstallers

**Type:** DWord

**Original Value:** 0

**New Value:** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

