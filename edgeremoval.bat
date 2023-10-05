@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit /b
#:: made by AveYo source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat
sp 'HKCU:\Volatile Environment' 'Edge_Removal' @'

$also_remove_webview = 0

$host.ui.RawUI.WindowTitle = 'Edge Removal - AveYo, 2023.09.09'
$remove_win32 = @("Microsoft Edge","Microsoft Edge Update"); $remove_appx = @("MicrosoftEdge"); $skip = @() # @("DevTools")
if ($also_remove_webview -eq 1) {$remove_win32 += "Microsoft EdgeWebView"; $remove_appx += "WebExperience","Win32WebViewHost"}

## 1 bonus! enter into powershell console: firefox / edge / webview to install a browser / reinstall edge or webview after removal
function global:firefox { $url = 'https://download.mozilla.org/?product=firefox-stub'
  $setup = "$((new-object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path)\Firefox Installer.exe"
  write-host $url; Invoke-WebRequest $url -OutFile $setup; start $setup
}
function global:edge { $url = 'https://go.microsoft.com/fwlink/?linkid=2108834&Channel=Stable&language=en'
  $setup = "$((new-object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path)\MicrosoftEdgeSetup.exe"
  write-host $url; Invoke-WebRequest $url -OutFile $setup; prepare_edge; start $setup
}
function global:webview { $url = 'https://go.microsoft.com/fwlink/p/?LinkId=2124703'
  $setup = "$((new-object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path)\MicrosoftEdgeWebview2Setup.exe"
  write-host $url; Invoke-WebRequest $url -OutFile $setup; prepare_webview; start $setup
}
## helper for set-itemproperty remove-itemproperty new-item remove-item with auto test-path
function global:sp_test_path { if (test-path $args[0]) {Microsoft.PowerShell.Management\Set-ItemProperty @args} else {
  Microsoft.PowerShell.Management\New-Item $args[0] -force -ea 0 >''; Microsoft.PowerShell.Management\Set-ItemProperty @args} }
function global:rp_test_path { if (test-path $args[0]) {Microsoft.PowerShell.Management\Remove-ItemProperty @args} }
function global:ni_test_path { if (-not (test-path $args[0])) {Microsoft.PowerShell.Management\New-Item @args} }
function global:ri_test_path { if (test-path $args[0]) {Microsoft.PowerShell.Management\Remove-Item @args} }
foreach ($f in 'sp','rp','ni','ri') {set-alias -Name $f -Value "${f}_test_path" -Scope Local -Option AllScope -force -ea 0}
## helper for edge reinstall - remove bundled OpenWebSearch redirector and edgeupdate policies
function global:prepare_edge {
  foreach ($f in 'ni','ri','sp','rp') {set-alias -Name $f -Value "${f}_test_path" -Scope Local -Option AllScope -force -ea 0}
  $MS=($env:ProgramFiles,${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem]+'\Microsoft\Edge\Application\msedge.exe'
  ri "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe" -recurse -force -ea 0
  ri "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe" -recurse -force -ea 0
  ri 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\microsoft-edge' -recurse -force -ea 0
  ri 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\MSEdgeHTM' -recurse -force -ea 0
  ni "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -force -ea 0 >''
  sp "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" '(Default)' "`"$MS`" --single-argument %%1" -force -ea 0 
  ni "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -force -ea 0 >''
  sp "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" '(Default)' "`"$MS`" --single-argument %%1" -force -ea 0
  foreach ($p in 'HKLM:\SOFTWARE\Policies','HKLM:\SOFTWARE','HKLM:\SOFTWARE\WOW6432Node') {
    rp "$p\Microsoft\EdgeUpdate" 'InstallDefault' -force -ea 0
    rp "$p\Microsoft\EdgeUpdate" 'Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}' -force -ea 0
    rp "$p\Microsoft\EdgeUpdate" 'Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' -force -ea 0
  }
  $edgeupdate='Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
  $webvupdate='Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
  $on_actions='on-os-upgrade','on-logon','on-logon-autolaunch','on-logon-startup-boost'
  foreach ($p in 'HKLM:\SOFTWARE','HKLM:\SOFTWARE\Wow6432Node') { foreach ($launch in $on_actions) {
    ri "$p\$edgeupdate\Commands\$launch" -force -ea 0; ri "$p\$webvupdate\Commands\$launch" -force -ea 0
  }}
}
## helper for webview reinstall - restore webexperience (widgets) if available
function global:prepare_webview {
  $cfg = @{Register=$true; ForceApplicationShutdown=$true; ForceUpdateFromAnyVersion=$true; DisableDevelopmentMode=$true} 
  dir "$env:ProgramFiles\WindowsApps\MicrosoftWindows.Client.WebExperience*\AppxManifest.xml" -rec -ea 0 | Add-AppxPackage @cfg
  dir "$env:SystemRoot\SystemApps\Microsoft.Win32WebViewHost*\AppxManifest.xml" -rec -ea 0 | Add-AppxPackage @cfg
  kill -name explorer -ea 0; if ((get-process -name 'explorer' -ea 0) -eq $null) {start explorer}
}

## 2 enable admin privileges
$D1=[uri].module.gettype('System.Diagnostics.Process')."GetM`ethods"(42) |where {$_.Name -eq 'SetPrivilege'} #`:no-ev-warn
'SeSecurityPrivilege','SeTakeOwnershipPrivilege','SeBackupPrivilege','SeRestorePrivilege'|foreach {$D1.Invoke($null, @("$_",2))}

## 3 shut edge & webview clone stuff down and gather install paths
$shut = 'explorer','Widgets','widgetservice','msedgewebview2','MicrosoftEdge*','chredge','msedge','edge'
$shut+= 'msteams','msfamily','WebViewHost','Clipchamp' 
cd $env:systemdrive; taskkill /im explorer.exe /f 2>&1 >''; foreach ($p in $shut) {kill -name $p -force -ea 0}
prepare_edge
## clear win32 uninstall block
foreach ($hk in 'HKCU:','HKLM:') { foreach ($wow in '','\Wow6432Node') { foreach ($i in $remove_win32) {
  rp "$hk\SOFTWARE${wow}\Microsoft\Windows\CurrentVersion\Uninstall\$i" 'NoRemove' -force -ea 0
  ni "$hk\SOFTWARE${wow}\Microsoft\EdgeUpdateDev" -force >''
  sp "$hk\SOFTWARE${wow}\Microsoft\EdgeUpdateDev" 'AllowUninstall' 1 -type Dword -force
}}}
## find all Edge setup.exe and gather BHO paths for OpenWebSearch / MSEdgeRedirect usage
$edges = @(); $bho = @(); 'LocalApplicationData','ProgramFilesX86','ProgramFiles' |foreach {
  $folder = [Environment]::GetFolderPath($_); $bho += dir "$folder\Microsoft\Edge*\ie_to_edge_stub.exe" -rec -ea 0
  if ($also_remove_webview -eq 1) {$edges += dir "$folder\Microsoft\Edge*\setup.exe" -rec -ea 0 |where {$_ -like '*EdgeWebView*'}}
  $edges += dir "$folder\Microsoft\Edge*\setup.exe" -rec -ea 0 |where {$_ -notlike '*EdgeWebView*'}
}
## use dedicated C:\Scripts path to save OpenWebSearch (due to Sigma rules FUD)
$DIR = "$env:SystemDrive\Scripts"; mkdir $DIR -ea 0 >''
## export OpenWebSearch innovative redirector - used by MSEdgeRedirect as well
foreach ($b in $bho) { if (test-path $b) { try {copy $b "$DIR\ie_to_edge_stub.exe" -force -ea 0} catch{} } }

## 4 remove found *Edge* appx packages with unblock tricks
$provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers; $eol = @()
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store -ea 0 |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageName = $appx.PackageName; $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName 
    ni "$store\Deprovisioned\$PackageFamilyName" -force >''; $PackageFamilyName  
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageName" -force >''} ; $eol += $PackageName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxprovisionedpackage -packagename $PackageName -online -allusers >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageFullName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageFullName = $appx.PackageFullName; 
    ni "$store\Deprovisioned\$appx.PackageFamilyName" -force >''; $PackageFullName
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageFullName" -force >''} ; $eol += $PackageFullName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxpackage -package $PackageFullName -allusers >''
  }
}

## 5 run found *Edge* setup.exe with uninstall args and wait in-between
foreach ($setup in $edges) { if (test-path $setup) {
  if ($setup -like '*EdgeWebView*') {$target = "--msedgewebview"} else {$target = "--msedge"}
  $removal = "--uninstall $target --system-level --verbose-logging --force-uninstall"
  try {write-host $setup $removal; start -wait $setup -args $removal} catch {}
  do {sleep 3} while ((get-process -name 'setup','MicrosoftEdge*' -ea 0).Path -like '*\Microsoft\Edge*')
}}

## 6 extra cleanup
foreach ($PF in $env:ProgramFiles,${env:ProgramFiles(x86)}) { if (test-path "$PF\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe") {
  write-host "$PF\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe /uninstall"
  start -wait "$PF\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe" -args '/uninstall'
  do {sleep 3} while ((get-process -name 'setup','MicrosoftEdge*' -ea 0).Path -like '*\Microsoft\Edge*')
  if ($also_remove_webview -eq 1) { foreach ($hk in 'HKCU:','HKLM:') { foreach ($wow in '','\Wow6432Node') {
    ri "$hk\SOFTWARE${wow}\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -rec -force -ea 0 }}
    ri "$PF\Microsoft\EdgeUpdate" -rec -force -ea 0; Unregister-ScheduledTask -TaskName MicrosoftEdgeUpdate* -Confirm:$false -ea 0
  }  
}}
$appdata = $([Environment]::GetFolderPath('ApplicationData'))
ri "$appdata\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk" -force
ri "$appdata\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" -force

## undo eol unblock trick to prevent latest cumulative update (LCU) failing 
foreach ($sid in $users) { foreach ($PackageName in $eol) {ri "$store\EndOfLife\$sid\$PackageName" -force >''} }

## set (almost) useless policies to prevent unsolicited reinstalls 
foreach ($p in 'HKLM:\SOFTWARE\Policies','HKLM:\SOFTWARE','HKLM:\SOFTWARE\WOW6432Node') {
  ni "$p\Microsoft\EdgeUpdate" -force >''
  sp "$p\Microsoft\EdgeUpdate" 'InstallDefault' 0 -type Dword -force
  sp "$p\Microsoft\EdgeUpdate" 'Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}' 0 -type Dword -force
  sp "$p\Microsoft\EdgeUpdate" 'Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' 1 -type Dword -force
  sp "$p\Microsoft\EdgeUpdate" 'DoNotUpdateToEdgeWithChromium' 1 -type Dword -force
}
$edgeupdate='Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
$webvupdate='Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
$on_actions='on-os-upgrade','on-logon','on-logon-autolaunch','on-logon-startup-boost'
foreach ($p in 'HKLM:\SOFTWARE','HKLM:\SOFTWARE\Wow6432Node') { foreach ($launch in $on_actions) {
  ni "$p\$edgeupdate\Commands\$launch" -force >''; sp "$p\$edgeupdate\Commands\$launch" 'CommandLine' 'systray.exe' -force
  ni "$p\$webvupdate\Commands\$launch" -force >''; sp "$p\$webvupdate\Commands\$launch" 'CommandLine' 'systray.exe' -force
}}

## 7 add bundled OpenWebSearch script to redirect microsoft-edge: anti-competitive links to the default browser
$MSEP = ($env:ProgramFiles,${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application'
$IFEO = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
$MIN = ('--headless','--width 1 --height 1')[([environment]::OSVersion.Version.Build) -gt 25179]
$CMD = "$env:systemroot\system32\conhost.exe $MIN" # AveYo: minimize prompt - see Terminal issue #13914
ni "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -force >''
sp "HKLM:\SOFTWARE\Classes\microsoft-edge" '(Default)' 'URL:microsoft-edge' -force
sp "HKLM:\SOFTWARE\Classes\microsoft-edge" 'URL Protocol' '' -force
sp "HKLM:\SOFTWARE\Classes\microsoft-edge" 'NoOpenWith' '' -force
sp "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" '(Default)' "`"$DIR\ie_to_edge_stub.exe`" %1" -force
ni "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -force >''
sp "HKLM:\SOFTWARE\Classes\MSEdgeHTM" 'NoOpenWith' '' -force
sp "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" '(Default)' "`"$DIR\ie_to_edge_stub.exe`" %1" -force
ni "$IFEO\ie_to_edge_stub.exe\0" -force >''
sp "$IFEO\ie_to_edge_stub.exe" 'UseFilter' 1 -type Dword -force
sp "$IFEO\ie_to_edge_stub.exe\0" 'FilterFullPath' "$DIR\ie_to_edge_stub.exe" -force
sp "$IFEO\ie_to_edge_stub.exe\0" 'Debugger' "$CMD $DIR\OpenWebSearch.cmd" -force
ni "$IFEO\msedge.exe\0" -force >''
sp "$IFEO\msedge.exe" 'UseFilter' 1 -type Dword -force
sp "$IFEO\msedge.exe\0" 'FilterFullPath' "$MSEP\msedge.exe" -force
sp "$IFEO\msedge.exe\0" 'Debugger' "$CMD $DIR\OpenWebSearch.cmd" -force

$OpenWebSearch = @$
@title OpenWebSearch Redux & echo off & set ?= open start menu web search, widgets links or help in your chosen browser - by AveYo
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

:dec_url brute url percent decoding by AveYo
set ".=%URL:!=}%"&setlocal enabledelayedexpansion& rem brute url percent decoding
set ".=!.:%%={!" &set ".=!.:{3A=:!" &set ".=!.:{2F=/!" &set ".=!.:{3F=?!" &set ".=!.:{23=#!" &set ".=!.:{5B=[!" &set ".=!.:{5D=]!"
set ".=!.:{40=@!"&set ".=!.:{21=}!" &set ".=!.:{24=$!" &set ".=!.:{26=&!" &set ".=!.:{27='!" &set ".=!.:{28=(!" &set ".=!.:{29=)!"
set ".=!.:{2A=*!"&set ".=!.:{2B=+!" &set ".=!.:{2C=,!" &set ".=!.:{3B=;!" &set ".=!.:{3D==!" &set ".=!.:{25=%%!"&set ".=!.:{20= !"
set ".=!.:{=%%!" &rem set ",=!.:%%=!" & if "!,!" neq "!.!" endlocal& set "URL=%.:}=!%" & call :dec_url
endlocal& set "URL=%.:}=!%" & exit /b
rem done

$@
[io.file]::WriteAllText("$DIR\OpenWebSearch.cmd", $OpenWebSearch)

## 8 done
$done = gp 'Registry::HKEY_Users\S-1-5-21*\Volatile*' Edge_Removal -ea 0; if ($done) {rp $done.PSPath Edge_Removal -force -ea 0}
if ((get-process -name 'explorer' -ea 0) -eq $null) {start explorer}

## 9 bonus enter into powershell console: firefox / edge / webview to install a browser / reinstall edge or webview after removal
${.} = [char]27; $firefox = "${.}[38;2;255;165;0m firefox"; $edge = "${.}[94m edge${.}[97m"; $webview = "${.}[94mwebview ${.}[97m"
write-host "`n${.}[40;32m EDGE REMOVED! ${.}[97m -GET-ANOTHER-BROWSER? ENTER:$firefox ${.}[97m -REINSTALL? ENTER:$edge / $webview"

## 0 ask to run script as admin
'@.replace("$@","'@").replace("@$","@'") -force -ea 0; $code='gp ''Registry::HKEY_Users\S-1-5-21*\Volatile*'' Edge_Removal -ea 0'
start powershell -args "-nop -noe -c & {iex(($code)[0].Edge_Removal)}" -verb runas
$_Press_Enter
#::
