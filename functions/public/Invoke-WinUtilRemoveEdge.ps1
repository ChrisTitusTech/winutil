function Invoke-WinUtilRemoveEdge {

  $Path = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe").FullName
  
  Write-Host "Unlocking The Offical Edge Uninstaller And Removing Microsoft Edge..."
  
  New-Item "C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force
  Start-Process $Path -ArgumentList '--uninstall --system-level --force-uninstall --delete-profile'
}
