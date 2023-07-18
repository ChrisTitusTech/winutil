$also_remove_webview = 1

$host.ui.RawUI.WindowTitle = 'Edge Removal '
## targets
$remove_win32 = @("Microsoft Edge","Microsoft Edge Update")
$remove_appx = @("MicrosoftEdge")
if ($also_remove_webview -eq 1) {
    $remove_win32 += "Microsoft EdgeWebView"
    $remove_appx += "Win32WebViewHost"
}

## set useless policies
foreach ($p in 'HKLM\SOFTWARE\Policies','HKLM\SOFTWARE') {
    Set-ItemProperty -Path "$p\Microsoft\EdgeUpdate" -Name InstallDefault -Value 0 -Type DWord >$null 2>$null
    Set-ItemProperty -Path "$p\Microsoft\EdgeUpdate" -Name Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062} -Value 0 -Type DWord >$null 2>$null
    Set-ItemProperty -Path "$p\Microsoft\EdgeUpdate" -Name Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5} -Value 1 -Type DWord >$null 2>$null
    Set-ItemProperty -Path "$p\Microsoft\EdgeUpdate" -Name DoNotUpdateToEdgeWithChromium -Value 1 -Type DWord >$null 2>$null
}
## clear win32 uninstall block
foreach ($hk in 'HKCU','HKLM') {
    foreach ($wow in '','\Wow6432Node') {
        foreach ($i in $remove_win32) {
            Remove-ItemProperty -Path "$hk\SOFTWARE${wow}\Microsoft\Windows\CurrentVersion\Uninstall\$i" -Name NoRemove -ErrorAction SilentlyContinue
        }
    }
}
## find all Edge setup.exe and gather BHO paths
$setup = @()
$bho = @()
$bho += "$env:ProgramData\ie_to_edge_stub.exe"
$bho += "$env:Public\ie_to_edge_stub.exe"
"LocalApplicationData","ProgramFilesX86","ProgramFiles" | ForEach-Object {
    $setup += Get-ChildItem "$($([Environment]::GetFolderPath($_)))\Microsoft\Edge*\setup.exe" -Recurse -ErrorAction SilentlyContinue
    $bho += Get-ChildItem "$($([Environment]::GetFolderPath($_)))\Microsoft\Edge*\ie_to_edge_stub.exe" -Recurse -ErrorAction SilentlyContinue
}
## shut edge down
foreach ($p in 'MicrosoftEdgeUpdate','chredge','msedge','edge','msedgewebview2','Widgets') {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
## use dedicated C:\Scripts path due to Sigma rules FUD
$DIR = "$env:SystemDrive\Scripts"
$null = New-Item -Path $DIR -ItemType Directory -ErrorAction SilentlyContinue
## export OpenWebSearch innovative redirector
foreach ($b in $bho) {
    if (Test-Path $b) {
        try {
            Copy-Item $b "$DIR\ie_to_edge_stub.exe" -Force -ErrorAction SilentlyContinue
        }
        catch {
        }
    }
}
## clear appx uninstall block and remove
$provisioned = Get-AppxProvisionedPackage -Online
$appxpackage = Get-AppxPackage -AllUsers
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$store_reg = $store.replace(':','')
$users = @('S-1-5-18')
if (Test-Path $store) {
    $users += $((Get-ChildItem $store | Where-Object { $_ -like '*S-1-5-21*' }).PSChildName)
}
foreach ($choice in $remove_appx) {
    if ('' -eq $choice.Trim()) {
        continue
    }
    foreach ($appx in $($provisioned | Where-Object { $_.PackageName -like "*$choice*" })) {
        $PackageFamilyName = ($appxpackage | Where-Object { $_.Name -eq $appx.DisplayName }).PackageFamilyName
        $PackageFamilyName
        Set-ItemProperty -Path "$store_reg\Deprovisioned\$PackageFamilyName" -Force >$null 2>$null
        cmd /c "dism /online /remove-provisionedappxpackage /packagename:$($appx.PackageName) >nul 2>nul"
    }
    foreach ($appx in $($appxpackage | Where-Object { $_.PackageFullName -like "*$choice*" })) {
        $inbox = (Get-ItemProperty "$store\InboxApplications\*$($appx.Name)*").Path.PSChildName
        $PackageFamilyName = $appx.PackageFamilyName
        $PackageFullName = $appx.PackageFullName
        $PackageFullName
        foreach ($app in $inbox) {
            Remove-ItemProperty -Path "$store_reg\InboxApplications\$app" -Force >$null 2>$null
        }
        Set-ItemProperty -Path "$store_reg\Deprovisioned\$PackageFamilyName" -Force >$null 2>$null
        foreach ($sid in $users) {
            Set-ItemProperty -Path "$store_reg\EndOfLife\$sid\$PackageFullName" -Force >$null 2>$null
        }
        dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >$null 2>$null
        remove-appxpackage -package "$PackageFullName" -AllUsers >$null 2>&1
        foreach ($sid in $users) {
            Remove-ItemProperty -Path "$store_reg\EndOfLife\$sid\$PackageFullName" -Force >$null 2>$null
        }
    }
}
## shut edge down, again
foreach ($p in 'MicrosoftEdgeUpdate','chredge','msedge','edge','msedgewebview2','Widgets') {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
## brute-run found Edge setup.exe with uninstall args
$purge = '--uninstall --system-level --force-uninstall'
if ($also_remove_webview -eq 1) {
    foreach ($s in $setup) {
        try {
            Start-Process -Wait -FilePath $s -ArgumentList "--msedgewebview $purge"
        }
        catch {
        }
    }
}
foreach ($s in $setup) {
    try {
        Start-Process -Wait -FilePath $s -ArgumentList "--msedge $purge"
    }
    catch {
    }
}
## cleanup
$desktop = $([Environment]::GetFolderPath('Desktop'))
$appdata = $([Environment]::GetFolderPath('ApplicationData'))
Remove-Item -Path "$appdata\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$appdata\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue

## add OpenWebSearch to redirect microsoft-edge: anti-competitive links to the default browser
$IFEO = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
$MSEP = ($env:ProgramFiles,${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application'
$MIN = ('--headless','--width 1 --height 1')[([environment]::OSVersion.Version.Build) -gt 25179]
$CMD = "$env:systemroot\system32\conhost.exe $MIN" # AveYo: minimize prompt - see Terminal issue #13914
Set-ItemProperty -Path HKCR\microsoft-edge -Force -Name '(default)' -Value 'URL:microsoft-edge' >$null
Set-ItemProperty -Path HKCR\microsoft-edge -Force -Name 'URL Protocol' -Value '' >$null
Set-ItemProperty -Path HKCR\microsoft-edge -Force -Name NoOpenWith -Value '' >$null
Set-ItemProperty -Path 'HKCR\microsoft-edge\shell\open\command' -Force -Name '(default)' -Value "$DIR\ie_to_edge_stub.exe %1" >$null
Set-ItemProperty -Path HKCR\MSEdgeHTM -Force -Name NoOpenWith -Value '' >$null
Set-ItemProperty -Path 'HKCR\MSEdgeHTM\shell\open\command' -Force -Name '(default)' -Value "$DIR\ie_to_edge_stub.exe %1" >$null
Set-ItemProperty -Path "$IFEO\ie_to_edge_stub.exe" -Force -Name UseFilter -Value 1 -Type DWord >$null
Set-ItemProperty -Path "$IFEO\ie_to_edge_stub.exe\0" -Force -Name FilterFullPath -Value "$DIR\ie_to_edge_stub.exe" >$null
Set-ItemProperty -Path "$IFEO\ie_to_edge_stub.exe\0" -Force -Name Debugger -Value "$CMD $DIR\OpenWebSearch.cmd" >$null
Set-ItemProperty -Path "$IFEO\msedge.exe" -Force -Name UseFilter -Value 1 -Type DWord >$null
Set-ItemProperty -Path "$IFEO\msedge.exe\0" -Force -Name FilterFullPath -Value "$MSEP\msedge.exe" >$null
Set-ItemProperty -Path "$IFEO\msedge.exe\0" -Force -Name Debugger -Value "$CMD $DIR\OpenWebSearch.cmd" >$null

$OpenWebSearch = @'
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
for /f "skip=2 tokens=* delims=" %%V in ('%{reg}% %4 %5 %6 %7 %8 %9 2^>nul') do set "{var}=%%V"
if defined %~3 (set "%~3=%{var}:*REG_=%" & set "%~3=%{var}%")
set "{var}=" & set "{reg}=" & exit /b

:dec_url
set "CLI=%URL:%%7E=~%"
set "CLI=%CLI:%%26=&%"
set "CLI=%CLI:%%2F=/%"
set "CLI=%CLI:%%2E=.%"
set "CLI=%CLI:%%3D==%"
set "CLI=%CLI:%%3F=?%"
set "CLI=%CLI:%%25=%%"
set "CLI=%CLI:%%23=#%"
set "CLI=%CLI:%%25=%%"
set "URL=%CLI%"
if /i "%URL%" neq "%CLI%" goto :dec_url
exit /b

:EOF
'@

$OpenWebSearch | Out-File "$DIR\OpenWebSearch.cmd" -Encoding ASCII -Force

Write-Host -NoNewline -ForegroundColor Green -BackgroundColor Black "`n EDGE REMOVED!"