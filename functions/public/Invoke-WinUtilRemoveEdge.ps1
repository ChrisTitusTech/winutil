function Invoke-WinUtilRemoveEdge {
  New-Item -Path "$Env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force

  $Path = Resolve-Path -Path "$Env:ProgramFiles (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" | Select-Object -Last 1
  Start-Process -FilePath $Path -ArgumentList '--uninstall --system-level --force-uninstall --delete-profile' -Wait

  Write-Host "Microsoft Edge was removed" -ForegroundColor Green
}
