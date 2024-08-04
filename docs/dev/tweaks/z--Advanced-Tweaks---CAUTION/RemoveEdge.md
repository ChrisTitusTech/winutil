# Remove Microsoft Edge - NOT RECOMMENDED

Last Updated: 2024-08-04


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Removes MS Edge when it gets reinstalled by updates. Credit: AveYo

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Remove Microsoft Edge - NOT RECOMMENDED",
  "Description": "Removes MS Edge when it gets reinstalled by updates. Credit: AveYo",
  "category": "z__Advanced Tweaks - CAUTION",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/RemoveEdge",
  "panel": "1",
  "Order": "a029_",
  "InvokeScript": [
    "
        #:: Standalone script by AveYo Source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat
        Invoke-WebRequest -Uri \"https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/edgeremoval.bat\" -OutFile \"$ENV:TEMP\\edgeremoval.bat\"
        Start-Process $ENV:temp\\edgeremoval.bat
        "
  ],
  "UndoScript": [
    "
      Write-Host \"Install Microsoft Edge\"
      Start-Process -FilePath winget -ArgumentList \"install -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge \" -NoNewWindow -Wait
      "
  ]
}
```
</details>

## Invoke Script

```powershell

        #:: Standalone script by AveYo Source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/edgeremoval.bat" -OutFile "$ENV:TEMP\edgeremoval.bat"
        Start-Process $ENV:temp\edgeremoval.bat
        

```
## Undo Script

```powershell

      Write-Host "Install Microsoft Edge"
      Start-Process -FilePath winget -ArgumentList "install -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge " -NoNewWindow -Wait
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
