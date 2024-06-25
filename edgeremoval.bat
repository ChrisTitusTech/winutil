cls

taskkill /f /im msedge.exe

takeown /f "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /a
icacls "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /grant administrators:F
del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"

takeown /f "C:\Users\Public\Desktop\Microsoft Edge.lnk" /a
icacls "C:\Users\Public\Desktop\Microsoft Edge.lnk" /grant administrators:F
del "C:\Users\Public\Desktop\Microsoft Edge.lnk"

takeown /f "%appdata%\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" /a
icacls "%appdata%\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" /grant administrators:F
del "%appdata%\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk"

takeown /f "C:\ProgramData\Microsoft\EdgeUpdate" /r /d y /a
icacls "C:\ProgramData\Microsoft\EdgeUpdate" /grant administrators:F /t
rd /s /q "C:\ProgramData\Microsoft\EdgeUpdate"

takeown /f "C:\Program Files (x86)\Microsoft\Edge" /r /d y /a
icacls "C:\Program Files (x86)\Microsoft\Edge" /grant administrators:F /t
rd /s /q "C:\Program Files (x86)\Microsoft\Edge"

takeown /f "C:\Program Files (x86)\Microsoft\EdgeCore" /r /d y /a
icacls "C:\Program Files (x86)\Microsoft\EdgeCore" /grant administrators:F /t
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeCore"

takeown /f "C:\Program Files (x86)\Microsoft\EdgeUpdate" /r /d y /a
icacls "C:\Program Files (x86)\Microsoft\EdgeUpdate" /grant administrators:F /t
rd /s /q "C:\Program Files (x86)\Microsoft\EdgeUpdate"

takeown /f "C:\Program Files (x86)\Microsoft\Temp" /r /d y /a
icacls "C:\Program Files (x86)\Microsoft\Temp" /grant administrators:F /t
rd /s /q "C:\Program Files (x86)\Microsoft\Temp"

takeown /f "%localappdata%\Microsoft\Edge" /r /d y /a
icacls "%localappdata%\Microsoft\Edge" /grant administrators:F /t
rd /s /q "%localappdata%\Microsoft\Edge"

reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Clients\StartMenuInternet\Microsoft Edge" /f
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v MicrosoftEdgeAutoLaunch_F4ACD3471AA35F400E44609491A8BAB7 /f
reg delete "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Run" /v MicrosoftEdgeAutoLaunch_F4ACD3471AA35F400E44609491A8BAB7 /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f
reg delete "Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f

sc stop MicrosoftEdgeElevationService
sc delete MicrosoftEdgeElevationService
sc stop edgeupdate
sc delete edgeupdate
sc stop edgeupdatem
sc delete edgeupdatem

schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore{04F36E1F-5519-4151-A6F3-BFE552405418}" /f
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA{CE09116A-59BE-406F-A83B-C465FACE32E2}" /f

pause
