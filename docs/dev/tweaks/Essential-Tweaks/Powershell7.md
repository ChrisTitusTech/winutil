﻿# Change Windows Terminal default: PowerShell 5 -> PowerShell 7


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

```json
Invoke-WPFTweakPS7 -action "PS7"

```
## Undo Script

```json
Invoke-WPFTweakPS7 -action "PS5"

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
