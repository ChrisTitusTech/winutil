# Remove Microsoft Edge - NOT RECOMMENDED


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


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
  "panel": "1",
  "Order": "a029_",
  "InvokeScript": [
    "\r\n        #:: Standalone script by AveYo Source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat\r\n        Invoke-WebRequest -Uri \"https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/edgeremoval.bat\" -OutFile \"$ENV:TEMP\\edgeremoval.bat\"\r\n        Start-Process $ENV:temp\\edgeremoval.bat\r\n        "
  ],
  "UndoScript": [
    "\r\n      Write-Host \"Install Microsoft Edge\"\r\n      Start-Process -FilePath winget -ArgumentList \"install -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge \" -NoNewWindow -Wait\r\n      "
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

