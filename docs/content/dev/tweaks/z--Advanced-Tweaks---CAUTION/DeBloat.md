# Remove ALL MS Store Apps - NOT RECOMMENDED

```json
  "WPFTweaksDeBloat": {
    "Content": "Remove ALL MS Store Apps - NOT RECOMMENDED",
    "Description": "USE WITH CAUTION!!! This will remove ALL Microsoft store apps.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a028_",
    "InvokeScript": [
      "
      Get-AppxPackage -AllUsers | Where SignatureKind -match Store | Remove-AppxPackage -AllUsers
      
      $TeamsPath = \"$Env:LocalAppData\\Microsoft\\Teams\\Update.exe\"

      if (Test-Path $TeamsPath) {
        Write-Host \"Uninstalling Teams\"
        Start-Process $TeamsPath -ArgumentList -uninstall -wait

        Write-Host \"Deleting Teams directory\"
        Remove-Item $TeamsPath -Recurse -Force
      }
      "
    ],
```
