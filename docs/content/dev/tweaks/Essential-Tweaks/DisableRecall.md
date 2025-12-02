# Disable Microsoft Recall

Last Updated: 2024-10-24


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables MS Recall built into Windows since 24H2.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
"WPFTweaksRecallOff": {
    "Content": "Disable Recall",
    "Description": "Turn Recall off",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a011_",
    "registry": [
      {

        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI",
        "Name": "DisableAIDataAnalysis",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "0"
      }
    ],
    "InvokeScript": [
      "
      Write-Host \"Disable Recall\"
      DISM /Online /Disable-Feature /FeatureName:Recall
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Enable Recall\"
      DISM /Online /Enable-Feature /FeatureName:Recall
      "
    ],
    "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/DisableRecall"
  },
```

</details>

## Invoke Script

```powershell

      Write-Host "Disable Recall"
      DISM /Online /Disable-Feature /FeatureName:Recall


```
## Undo Script

```powershell

      Write-Host "Enable Recall"
      DISM /Online /Enable-Feature /FeatureName:Recall


```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: DisableAIDataAnalysis

**Type:** DWord

**Original Value:** 0

**New Value:** 1

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)
