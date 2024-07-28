# Disable Hibernation


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Hibernation is really meant for laptops as it saves what's in memory before turning the pc off. It really should never be used, but some people are lazy and rely on it. Don't be like Bob. Bob likes hibernation.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Disable Hibernation",
    "Description":  "Hibernation is really meant for laptops as it saves what\u0027s in memory before turning the pc off. It really should never be used, but some people are lazy and rely on it. Don\u0027t be like Bob. Bob likes hibernation.",
    "category":  "Essential Tweaks",
    "panel":  "1",
    "Order":  "a005_",
    "registry":  [
                     {
                         "Path":  "HKLM:\\System\\CurrentControlSet\\Control\\Session Manager\\Power",
                         "Name":  "HibernateEnabled",
                         "Type":  "DWord",
                         "Value":  "0",
                         "OriginalValue":  "1"
                     },
                     {
                         "Path":  "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FlyoutMenuSettings",
                         "Name":  "ShowHibernateOption",
                         "Type":  "DWord",
                         "Value":  "0",
                         "OriginalValue":  "1"
                     }
                 ],
    "InvokeScript":  [
                         "powercfg.exe /hibernate off"
                     ],
    "UndoScript":  [
                       "powercfg.exe /hibernate on"
                   ]
}
```
</details>

## Invoke Script

```json
powercfg.exe /hibernate off

```
## Undo Script

```json
powercfg.exe /hibernate on

```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
### Registry Key: HibernateEnabled
**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ShowHibernateOption
**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

