# Remove OneDrive

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Moves OneDrive files to Default Home Folders and Uninstalls it.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Remove OneDrive",
    "Description":  "Moves OneDrive files to Default Home Folders and Uninstalls it.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "z__Advanced Tweaks - CAUTION",
    "panel":  "1",
    "Order":  "a030_",
    "InvokeScript":  [
                         "\r\n      $OneDrivePath = $($env:OneDrive)\r\n      Write-Host \"Removing OneDrive\"\r\n      $regPath = \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\OneDriveSetup.exe\"\r\n      if (Test-Path $regPath){\r\n          $OneDriveUninstallString = Get-ItemPropertyValue \"$regPath\" -Name \"UninstallString\"\r\n          $OneDriveExe, $OneDriveArgs = $OneDriveUninstallString.Split(\" \")\r\n          Start-Process -FilePath $OneDriveExe -ArgumentList \"$OneDriveArgs /silent\" -NoNewWindow -Wait\r\n      }\r\n      else{\r\n          Write-Host \"Onedrive dosn\u0027t seem to be installed anymore\" -ForegroundColor Red\r\n          return\r\n      }\r\n      # Check if OneDrive got Uninstalled\r\n      if (-not (Test-Path $regPath)){\r\n      Write-Host \"Copy downloaded Files from the OneDrive Folder to Root UserProfile\"\r\n      Start-Process -FilePath powershell -ArgumentList \"robocopy \u0027$($OneDrivePath)\u0027 \u0027$($env:USERPROFILE.TrimEnd())\\\u0027 /mov /e /xj\" -NoNewWindow -Wait\r\n\r\n      Write-Host \"Removing OneDrive leftovers\"\r\n      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue \"$env:localappdata\\Microsoft\\OneDrive\"\r\n      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue \"$env:localappdata\\OneDrive\"\r\n      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue \"$env:programdata\\Microsoft OneDrive\"\r\n      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue \"$env:systemdrive\\OneDriveTemp\"\r\n      reg delete \"HKEY_CURRENT_USER\\Software\\Microsoft\\OneDrive\" -f\r\n      # check if directory is empty before removing:\r\n      If ((Get-ChildItem \"$OneDrivePath\" -Recurse | Measure-Object).Count -eq 0) {\r\n          Remove-Item -Recurse -Force -ErrorAction SilentlyContinue \"$OneDrivePath\"\r\n      }\r\n\r\n      Write-Host \"Remove Onedrive from explorer sidebar\"\r\n      Set-ItemProperty -Path \"HKCR:\\CLSID\\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\" -Name \"System.IsPinnedToNameSpaceTree\" -Value 0\r\n      Set-ItemProperty -Path \"HKCR:\\Wow6432Node\\CLSID\\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\" -Name \"System.IsPinnedToNameSpaceTree\" -Value 0\r\n\r\n      Write-Host \"Removing run hook for new users\"\r\n      reg load \"hku\\Default\" \"C:\\Users\\Default\\NTUSER.DAT\"\r\n      reg delete \"HKEY_USERS\\Default\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run\" /v \"OneDriveSetup\" /f\r\n      reg unload \"hku\\Default\"\r\n\r\n      Write-Host \"Removing startmenu entry\"\r\n      Remove-Item -Force -ErrorAction SilentlyContinue \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk\"\r\n\r\n      Write-Host \"Removing scheduled task\"\r\n      Get-ScheduledTask -TaskPath \u0027\\\u0027 -TaskName \u0027OneDrive*\u0027 -ea SilentlyContinue | Unregister-ScheduledTask -Confirm:$false\r\n\r\n      # Add Shell folders restoring default locations\r\n      Write-Host \"Shell Fixing\"\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"AppData\" -Value \"$env:userprofile\\AppData\\Roaming\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Cache\" -Value \"$env:userprofile\\AppData\\Local\\Microsoft\\Windows\\INetCache\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Cookies\" -Value \"$env:userprofile\\AppData\\Local\\Microsoft\\Windows\\INetCookies\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Favorites\" -Value \"$env:userprofile\\Favorites\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"History\" -Value \"$env:userprofile\\AppData\\Local\\Microsoft\\Windows\\History\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Local AppData\" -Value \"$env:userprofile\\AppData\\Local\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"My Music\" -Value \"$env:userprofile\\Music\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"My Video\" -Value \"$env:userprofile\\Videos\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"NetHood\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Network Shortcuts\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"PrintHood\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Printer Shortcuts\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Programs\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Recent\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Recent\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"SendTo\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\SendTo\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Start Menu\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Startup\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Templates\" -Value \"$env:userprofile\\AppData\\Roaming\\Microsoft\\Windows\\Templates\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"{374DE290-123F-4565-9164-39C4925E467B}\" -Value \"$env:userprofile\\Downloads\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Desktop\" -Value \"$env:userprofile\\Desktop\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"My Pictures\" -Value \"$env:userprofile\\Pictures\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"Personal\" -Value \"$env:userprofile\\Documents\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"{F42EE2D3-909F-4907-8871-4C22FC0BF756}\" -Value \"$env:userprofile\\Documents\" -Type ExpandString\r\n      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders\" -Name \"{0DDD015D-B06C-45D5-8C4C-F59713854639}\" -Value \"$env:userprofile\\Pictures\" -Type ExpandString\r\n      Write-Host \"Restarting explorer\"\r\n      taskkill.exe /F /IM \"explorer.exe\"\r\n      Start-Process \"explorer.exe\"\r\n\r\n      Write-Host \"Waiting for explorer to complete loading\"\r\n      Write-Host \"Please Note - The OneDrive folder at $OneDrivePath may still have items in it. You must manually delete it, but all the files should already be copied to the base user folder.\"\r\n      Write-Host \"If there are Files missing afterwards, please Login to Onedrive.com and Download them manually\" -ForegroundColor Yellow\r\n      Start-Sleep 5\r\n      }\r\n      else{\r\n      Write-Host \"Something went Wrong during the Unistallation of OneDrive\" -ForegroundColor Red\r\n      }\r\n      "
                     ],
    "UndoScript":  [
                       "\r\n      Write-Host \"Install OneDrive\"\r\n      Start-Process -FilePath winget -ArgumentList \"install -e --accept-source-agreements --accept-package-agreements --silent Microsoft.OneDrive \" -NoNewWindow -Wait\r\n      "
                   ]
}
```
</details>

## Invoke Script

```powershell

      $OneDrivePath = $($env:OneDrive)
      Write-Host "Removing OneDrive"
      $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
      if (Test-Path $regPath){
          $OneDriveUninstallString = Get-ItemPropertyValue "$regPath" -Name "UninstallString"
          $OneDriveExe, $OneDriveArgs = $OneDriveUninstallString.Split(" ")
          Start-Process -FilePath $OneDriveExe -ArgumentList "$OneDriveArgs /silent" -NoNewWindow -Wait
      }
      else{
          Write-Host "Onedrive dosn't seem to be installed anymore" -ForegroundColor Red
          return
      }
      # Check if OneDrive got Uninstalled
      if (-not (Test-Path $regPath)){
      Write-Host "Copy downloaded Files from the OneDrive Folder to Root UserProfile"
      Start-Process -FilePath powershell -ArgumentList "robocopy '$($OneDrivePath)' '$($env:USERPROFILE.TrimEnd())\' /mov /e /xj" -NoNewWindow -Wait

      Write-Host "Removing OneDrive leftovers"
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\Microsoft\OneDrive"
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:localappdata\OneDrive"
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:programdata\Microsoft OneDrive"
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:systemdrive\OneDriveTemp"
      reg delete "HKEY_CURRENT_USER\Software\Microsoft\OneDrive" -f
      # check if directory is empty before removing:
      If ((Get-ChildItem "$OneDrivePath" -Recurse | Measure-Object).Count -eq 0) {
          Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$OneDrivePath"
      }

      Write-Host "Remove Onedrive from explorer sidebar"
      Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
      Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0

      Write-Host "Removing run hook for new users"
      reg load "hku\Default" "C:\Users\Default\NTUSER.DAT"
      reg delete "HKEY_USERS\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
      reg unload "hku\Default"

      Write-Host "Removing startmenu entry"
      Remove-Item -Force -ErrorAction SilentlyContinue "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"

      Write-Host "Removing scheduled task"
      Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ea SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

      # Add Shell folders restoring default locations
      Write-Host "Shell Fixing"
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "AppData" -Value "$env:userprofile\AppData\Roaming" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cache" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCache" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Cookies" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\INetCookies" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Favorites" -Value "$env:userprofile\Favorites" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "History" -Value "$env:userprofile\AppData\Local\Microsoft\Windows\History" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Local AppData" -Value "$env:userprofile\AppData\Local" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Music" -Value "$env:userprofile\Music" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Video" -Value "$env:userprofile\Videos" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "NetHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Network Shortcuts" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "PrintHood" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Printer Shortcuts" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Programs" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Recent" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Recent" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "SendTo" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\SendTo" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Start Menu" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Startup" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Templates" -Value "$env:userprofile\AppData\Roaming\Microsoft\Windows\Templates" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}" -Value "$env:userprofile\Downloads" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Desktop" -Value "$env:userprofile\Desktop" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "My Pictures" -Value "$env:userprofile\Pictures" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "Personal" -Value "$env:userprofile\Documents" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" -Value "$env:userprofile\Documents" -Type ExpandString
      Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{0DDD015D-B06C-45D5-8C4C-F59713854639}" -Value "$env:userprofile\Pictures" -Type ExpandString
      Write-Host "Restarting explorer"
      taskkill.exe /F /IM "explorer.exe"
      Start-Process "explorer.exe"

      Write-Host "Waiting for explorer to complete loading"
      Write-Host "Please Note - The OneDrive folder at $OneDrivePath may still have items in it. You must manually delete it, but all the files should already be copied to the base user folder."
      Write-Host "If there are Files missing afterwards, please Login to Onedrive.com and Download them manually" -ForegroundColor Yellow
      Start-Sleep 5
      }
      else{
      Write-Host "Something went Wrong during the Unistallation of OneDrive" -ForegroundColor Red
      }
      

```
## Undo Script

```powershell

      Write-Host "Install OneDrive"
      Start-Process -FilePath winget -ArgumentList "install -e --accept-source-agreements --accept-package-agreements --silent Microsoft.OneDrive " -NoNewWindow -Wait
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

