# WinGet Reinstall

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "WinGet Reinstall",
  "category": "Fixes",
  "panel": "1",
  "Order": "a044_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/Winutil/dev/features/Fixes/Winget"
}
```

</details>

## Function: Invoke-WPFFixesWinget

```powershell
function Invoke-WPFFixesWinget {

    <#

    .SYNOPSIS
        Fixes Winget by running choco install winget
    .DESCRIPTION
        BravoNorris for the fantastic idea of a button to reinstall winget
    #>
    # Install Choco if not already present
    Install-WinutilChoco
    Start-Process -FilePath "choco" -ArgumentList "install winget -y --force" -NoNewWindow -Wait

}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

