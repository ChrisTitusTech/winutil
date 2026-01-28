# Remove Microsoft Edge

# Json File
```json
  "WPFTweaksRemoveEdge": {
    "Content": "Remove Microsoft Edge",
    "Description": "Unblocks Microsoft Edge uninstaller restrictions than uses that uninstaller to remove Microsoft Edge",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a028_",
    "InvokeScript": [
      "Invoke-WinUtilRemoveEdge"
    ],
    "UndoScript": [
      "
      Write-Host 'Installing Microsoft Edge...'
      winget install Microsoft.Edge --source winget
      "
    ],
```
# Function
```json
function Invoke-WinUtilRemoveEdge {
  Write-Host "Unlocking The Offical Edge Uninstaller And Removing Microsoft Edge..."

  $Path = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe")[0].FullName
  New-Item "C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force
  Start-Process $Path -ArgumentList '--uninstall --system-level --force-uninstall --delete-profile'
}
```
