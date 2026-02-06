# Delete Temporary Files

```json
  "WPFTweaksDeleteTempFiles": {
    "Content": "Delete Temporary Files",
    "Description": "Erases TEMP Folders",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a002_",
    "InvokeScript": [
      "
      Remove-Item -Path \"$Env:Temp\\*\" -Recurse -Force
      Remove-Item -Path \"$Env:SystemRoot\\Temp\\*\" -Recurse -Force
      "
    ],
```
