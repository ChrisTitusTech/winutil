function Invoke-WinUtilRemoveEdge {

  $Version = (Get-AppxPackage Microsoft.MicrosoftEdge.Stable).Version
  $Path = "C:\Program Files (x86)\Microsoft\Edge\Application\$Version\Installer\setup.exe"
  
  Write-Host "Unlocking The Offical Edge Uninstaller than Removing Microsoft Edge..."
  
  New-Item "C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force
  Start-Process $Path -ArgumentList '--uninstall --system-level --force-uninstall --delete-profile'
}
