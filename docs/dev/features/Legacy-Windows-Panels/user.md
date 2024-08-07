# User Accounts

Last Updated: 2024-08-07


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "User Accounts",
  "category": "Legacy Windows Panels",
  "panel": "2",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Legacy-Windows-Panels/user"
}
```

</details>

## Function: Invoke-WPFControlPanel

```powershell
function Invoke-WPFControlPanel {
    <#

    .SYNOPSIS
        Opens the requested legacy panel

    .PARAMETER Panel
        The panel to open

    #>
    param($Panel)

    switch ($Panel) {
        "WPFPanelcontrol" {cmd /c control}
        "WPFPanelnetwork" {cmd /c ncpa.cpl}
        "WPFPanelpower"   {cmd /c powercfg.cpl}
        "WPFPanelregion"  {cmd /c intl.cpl}
        "WPFPanelsound"   {cmd /c mmsys.cpl}
        "WPFPanelsystem"  {cmd /c sysdm.cpl}
        "WPFPaneluser"    {cmd /c "control userpasswords2"}
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

