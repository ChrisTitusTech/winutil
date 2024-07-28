# Set Classic Right-Click Menu 


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Great Windows 11 tweak to bring back good context menus when right clicking things in explorer.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Set Classic Right-Click Menu ",
  "Description": "Great Windows 11 tweak to bring back good context menus when right clicking things in explorer.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a027_",
  "InvokeScript": [
    "\r\n      New-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Name \"InprocServer32\" -force -value \"\"\r\n      Write-Host Restarting explorer.exe ...\r\n      $process = Get-Process -Name \"explorer\"\r\n      Stop-Process -InputObject $process\r\n      "
  ],
  "UndoScript": [
    "\r\n      Remove-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Recurse -Confirm:$false -Force\r\n      # Restarting Explorer in the Undo Script might not be necessary, as the Registry change without restarting Explorer does work, but just to make sure.\r\n      Write-Host Restarting explorer.exe ...\r\n      $process = Get-Process -Name \"explorer\"\r\n      Stop-Process -InputObject $process\r\n      "
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

