@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit /b
#:: double-click to run or just copy-paste into powershell - it's a standalone hybrid script
sp 'HKCU:\Volatile Environment' 'Edge_Removal' @'

$also_remove_webview = 1

$host.ui.RawUI.WindowTitle = 'Edge Removal '
## targets
$remove_win32 = @("Microsoft Edge","Microsoft Edge Update"); $remove_appx = @("MicrosoftEdge")
if ($also_remove_webview -eq 1) {$remove_win32 += "Microsoft EdgeWebView"; $remove_appx += "Win32WebViewHost"}
## enable admin privileges
$D1=[uri].module.gettype('System.Diagnostics.Process')."GetM`ethods"(42) |where {$_.Name -eq 'SetPrivilege'} #`:no-ev-warn
'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege'|foreach {$D1.Invoke($null, @("$_",2))}
## set useless policies
foreach ($p in 'HKLM\SOFTWARE\Policies','HKLM\SOFTWARE') {
  cmd /c "reg add ""$p\Microsoft\EdgeUpdate"" /f /v InstallDefault /d 0 /t reg_dword >nul 2>nul"
  cmd /c "reg add ""$p\Microsoft\EdgeUpdate"" /f /v Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062} /d 0 /t reg_dword >nul 2>nul"
  cmd /c "reg add ""$p\Microsoft\EdgeUpdate"" /f /v Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5} /d 1 /t reg_dword >nul 2>nul"
  cmd /c "reg add ""$p\Microsoft\EdgeUpdate"" /f /v DoNotUpdateToEdgeWithChromium /d 1 /t reg_dword >nul 2>nul"
}
## clear win32 uninstall block
foreach ($hk in 'HKCU','HKLM') {foreach ($wow in '','\Wow6432Node') {foreach ($i in $remove_win32) {
  cmd /c "reg delete ""$hk\SOFTWARE${wow}\Microsoft\Windows\CurrentVersion\Uninstall\$i"" /f /v NoRemove >nul 2>nul"
}}}
## find all Edge setup.exe and gather BHO paths
$setup = @(); $bho = @(); $bho += "$env:ProgramData\ie_to_edge_stub.exe"; $bho += "$env:Public\ie_to_edge_stub.exe"
"LocalApplicationData","ProgramFilesX86","ProgramFiles" |foreach {
  $setup += dir $($([Environment]::GetFolderPath($_)) + '\Microsoft\Edge*\setup.exe') -rec -ea 0
  $bho += dir $($([Environment]::GetFolderPath($_)) + '\Microsoft\Edge*\ie_to_edge_stub.exe') -rec -ea 0
}
## shut edge down
foreach ($p in 'MicrosoftEdgeUpdate','chredge','msedge','edge','msedgewebview2','Widgets') { kill -name $p -force -ea 0 }
## use dedicated C:\Scripts path due to Sigma rules FUD
$DIR = "$env:SystemDrive\Scripts"; $null = mkdir $DIR -ea 0
## export OpenWebSearch innovative redirector
foreach ($b in $bho) { if (test-path $b) { try {copy $b "$DIR\ie_to_edge_stub.exe" -force -ea 0} catch{} } }
## clear appx uninstall block and remove
$provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'; $store_reg = $store.replace(':','')
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName; $PackageFamilyName
    cmd /c "reg add ""$store_reg\Deprovisioned\$PackageFamilyName"" /f >nul 2>nul"
    cmd /c "dism /online /remove-provisionedappxpackage /packagename:$($appx.PackageName) >nul 2>nul"
    #powershell -nop -c remove-appxprovisionedpackage -packagename "'$($appx.PackageName)'" -online 2>&1 >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $inbox = (gp "$store\InboxApplications\*$($appx.Name)*" Path).PSChildName
    $PackageFamilyName = $appx.PackageFamilyName; $PackageFullName = $appx.PackageFullName; $PackageFullName
    foreach ($app in $inbox) {cmd /c "reg delete ""$store_reg\InboxApplications\$app"" /f >nul 2>nul" }
    cmd /c "reg add ""$store_reg\Deprovisioned\$PackageFamilyName"" /f >nul 2>nul"
    foreach ($sid in $users) {cmd /c "reg add ""$store_reg\EndOfLife\$sid\$PackageFullName"" /f >nul 2>nul"}
    cmd /c "dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >nul 2>nul"
    powershell -nop -c "remove-appxpackage -package '$PackageFullName' -AllUsers" 2>&1 >''
    foreach ($sid in $users) {cmd /c "reg delete ""$store_reg\EndOfLife\$sid\$PackageFullName"" /f >nul 2>nul"}
  }
}
## shut edge down, again
foreach ($p in 'MicrosoftEdgeUpdate','chredge','msedge','edge','msedgewebview2','Widgets') { kill -name $p -force -ea 0 }
## brute-run found Edge setup.exe with uninstall args
$purge = '--uninstall --system-level --force-uninstall'
if ($also_remove_webview -eq 1) { foreach ($s in $setup) { try{ start -wait $s -args "--msedgewebview $purge" } catch{} } }
foreach ($s in $setup) { try{ start -wait $s -args "--msedge $purge" } catch{} }
## prevent latest cumulative update (LCU) failing due to non-matching EndOfLife Edge entries
foreach ($i in $remove_appx) {
  dir "$store\EndOfLife" -rec -ea 0 |where {$_ -like "*${i}*"} |foreach {cmd /c "reg delete ""$($_.Name)"" /f >nul 2>nul"}
  dir "$store\Deleted\EndOfLife" -rec -ea 0 |where {$_ -like "*${i}*"} |foreach {cmd /c "reg delete ""$($_.Name)"" /f >nul 2>nul"}
}
## extra cleanup
$desktop = $([Environment]::GetFolderPath('Desktop')); $appdata = $([Environment]::GetFolderPath('ApplicationData'))
del "$appdata\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk" -force -ea 0
del "$appdata\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" -force -ea 0
del "$desktop\Microsoft Edge.lnk" -force -ea 0

## add OpenWebSearch to redirect microsoft-edge: anti-competitive links to the default browser
$IFEO = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
$MSEP = ($env:ProgramFiles,${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application'
$MIN = ('--headless','--width 1 --height 1')[([environment]::OSVersion.Version.Build) -gt 25179]
$CMD = "$env:systemroot\system32\conhost.exe $MIN" # AveYo: minimize prompt - see Terminal issue #13914
cmd /c "reg add HKCR\microsoft-edge /f /ve /d URL:microsoft-edge >nul"
cmd /c "reg add HKCR\microsoft-edge /f /v ""URL Protocol"" /d """" >nul"
cmd /c "reg add HKCR\microsoft-edge /f /v NoOpenWith /d """" >nul"
cmd /c "reg add HKCR\microsoft-edge\shell\open\command /f /ve /d ""$DIR\ie_to_edge_stub.exe %1"" >nul"
cmd /c "reg add HKCR\MSEdgeHTM /f /v NoOpenWith /d """" >nul"
cmd /c "reg add HKCR\MSEdgeHTM\shell\open\command /f /ve /d ""$DIR\ie_to_edge_stub.exe %1"" >nul"
cmd /c "reg add ""$IFEO\ie_to_edge_stub.exe"" /f /v UseFilter /d 1 /t reg_dword >nul >nul"
cmd /c "reg add ""$IFEO\ie_to_edge_stub.exe\0"" /f /v FilterFullPath /d ""$DIR\ie_to_edge_stub.exe"" >nul"
cmd /c "reg add ""$IFEO\ie_to_edge_stub.exe\0"" /f /v Debugger /d ""$CMD $DIR\OpenWebSearch.cmd"" >nul"
cmd /c "reg add ""$IFEO\msedge.exe"" /f /v UseFilter /d 1 /t reg_dword >nul"
cmd /c "reg add ""$IFEO\msedge.exe\0"" /f /v FilterFullPath /d ""$MSEP\msedge.exe"" >nul"
cmd /c "reg add ""$IFEO\msedge.exe\0"" /f /v Debugger /d ""$CMD $DIR\OpenWebSearch.cmd"" >nul"

$OpenWebSearch = @$
@title OpenWebSearch Redux & echo off & set ?= open start menu web search, widgets links or help in your chosen browser
for /f %%E in ('"prompt $E$S& for %%e in (1) do rem"') do echo;%%E[2t 2>nul & rem AveYo: minimize prompt
call :reg_var "HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" ProgID ProgID
if /i "%ProgID%" equ "MSEdgeHTM" echo;Default browser is set to Edge! Change it or remove OpenWebSearch script. & pause & exit /b
call :reg_var "HKCR\%ProgID%\shell\open\command" "" Browser
set Choice=& for %%. in (%Browser%) do if not defined Choice set "Choice=%%~."
call :reg_var "HKCR\MSEdgeMHT\shell\open\command" "" FallBack
set "Edge=" & for %%. in (%FallBack%) do if not defined Edge set "Edge=%%~."
set "URI=" & set "URL=" & set "NOOP=" & set "PassTrough=%Edge:msedge=edge%"
set "CLI=%CMDCMDLINE:"=``% "
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe`` =%"
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe =%"
if defined CLI set "CLI=%CLI:*msedge.exe`` =%"
if defined CLI set "CLI=%CLI:*msedge.exe =%"
set "FIX=%CLI:~-1%"
if defined CLI if "%FIX%"==" " set "CLI=%CLI:~0,-1%"
if defined CLI set "RED=%CLI:microsoft-edge=%"
if defined CLI set "URL=%CLI:http=%"
if defined CLI set "ARG=%CLI:``="%"
if "%CLI%" equ "%RED%" (set NOOP=1) else if "%CLI%" equ "%URL%" (set NOOP=1)
if defined NOOP if exist "%PassTrough%" start "" "%PassTrough%" %ARG%
if defined NOOP exit /b
set "URL=%CLI:*microsoft-edge=%"
set "URL=http%URL:*http=%"
set "FIX=%URL:~-2%"
if defined URL if "%FIX%"=="``" set "URL=%URL:~0,-2%"
call :dec_url
start "" "%Choice%" "%URL%"
exit

:reg_var [USAGE] call :reg_var "HKCU\Volatile Environment" value-or-"" variable [extra options]
set {var}=& set {reg}=reg query "%~1" /v %2 /z /se "," /f /e& if %2=="" set {reg}=reg query "%~1" /ve /z /se "," /f /e
for /f "skip=2 tokens=* delims=" %%V in ('%{reg}% %4 %5 %6 %7 %8 %9 2^>nul') do if not defined {var} set "{var}=%%V"
if not defined {var} (set {reg}=& set "%~3="& exit /b) else if %2=="" set "{var}=%{var}:*)    =%"& rem AveYo: v3
if not defined {var} (set {reg}=& set "%~3="& exit /b) else set {reg}=& set "%~3=%{var}:*)    =%"& set {var}=& exit /b

:dec_url brute url percent decoding  
set ".=%URL:!=}%"&setlocal enabledelayedexpansion& rem brute url percent decoding
set ".=!.:%%={!" &set ".=!.:{3A=:!" &set ".=!.:{2F=/!" &set ".=!.:{3F=?!" &set ".=!.:{23=#!" &set ".=!.:{5B=[!" &set ".=!.:{5D=]!"
set ".=!.:{40=@!"&set ".=!.:{21=}!" &set ".=!.:{24=$!" &set ".=!.:{26=&!" &set ".=!.:{27='!" &set ".=!.:{28=(!" &set ".=!.:{29=)!"
set ".=!.:{2A=*!"&set ".=!.:{2B=+!" &set ".=!.:{2C=,!" &set ".=!.:{3B=;!" &set ".=!.:{3D==!" &set ".=!.:{25=%%!"&set ".=!.:{20= !"
set ".=!.:{=%%!" &rem set ",=!.:%%=!" & if "!,!" neq "!.!" endlocal& set "URL=%.:}=!%" & call :dec_url
endlocal& set "URL=%.:}=!%" & exit /b
rem done

$@
[io.file]::WriteAllText("$DIR\OpenWebSearch.cmd", $OpenWebSearch) >''
## cleanup
$cleanup = gp 'Registry::HKEY_Users\S-1-5-21*\Volatile*' Edge_Removal -ea 0
if ($cleanup) {rp $cleanup.PSPath Edge_Removal -force -ea 0}


write-host -nonew -fore green -back black "`n EDGE REMOVED!"; 
exit

## ask to run script as admin
'@.replace("$@","'@").replace("@$","@'") -force -ea 0;
$A = '-nop -noe -c & {iex((gp ''Registry::HKEY_Users\S-1-5-21*\Volatile*'' Edge_Removal -ea 0)[0].Edge_Removal)}'
start powershell -args $A -verb runas
$_Press_Enter
#::