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
  reg add "$p\Microsoft\EdgeUpdate" /f /v InstallDefault /d 0 /t reg_dword >$null 2>$null
  reg add "$p\Microsoft\EdgeUpdate" /f /v Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062} /d 0 /t reg_dword >$null 2>$null
  reg add "$p\Microsoft\EdgeUpdate" /f /v Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5} /d 1 /t reg_dword >$null 2>$null
  reg add "$p\Microsoft\EdgeUpdate" /f /v DoNotUpdateToEdgeWithChromium /d 1 /t reg_dword >$null 2>$null
}
## clear win32 uninstall block
foreach ($hk in 'HKCU','HKLM') {
    foreach ($wow in '','\Wow6432Node') {
        foreach ($i in $remove_win32) {
            reg delete "$hk\SOFTWARE${wow}\Microsoft\Windows\CurrentVersion\Uninstall\$i" /f /v NoRemove >$null 2>$null
        }
    }
}
## find all Edge setup.exe and gather BHO paths
$setup = @()
$bho = @()
$bho += "$env:ProgramData\ie_to_edge_stub.exe"
$bho += "$env:Public\ie_to_edge_stub.exe"
"LocalApplicationData","ProgramFilesX86","ProgramFiles" | foreach {
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
        reg add "$store_reg\Deprovisioned\$PackageFamilyName" /f >$null 2>$null
        dism /online /remove-provisionedappxpackage /packagename:$($appx.PackageName) >$null 2>$null
    }
    foreach ($appx in $($appxpackage | Where-Object { $_.PackageFullName -like "*$choice*" })) {
        $inbox = (Get-ItemProperty "$store\InboxApplications\*$($appx.Name)*").Path.PSChildName
        $PackageFamilyName = $appx.PackageFamilyName
        $PackageFullName = $appx.PackageFullName
        $PackageFullName
        foreach ($app in $inbox) {
            reg delete "$store_reg\InboxApplications\$app" /f >$null 2>$null
        }
        reg add "$store_reg\Deprovisioned\$PackageFamilyName" /f >$null 2>$null
        foreach ($sid in $users) {
            reg add "$store_reg\EndOfLife\$sid\$PackageFullName" /f >$null 2>$null
        }
        dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >$null 2>$null
        remove-appxpackage -package "$PackageFullName" -AllUsers >$null 2>&1
        foreach ($sid in $users) {
            reg delete "$store_reg\EndOfLife\$sid\$PackageFullName" /f >$null 2>$null
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
## prevent latest cumulative update (LCU) failing due to non-matching EndOfLife Edge entries
foreach ($i in $remove_appx) {
    Get-ChildItem "$store\EndOfLife" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_ -like "*${i}*" } | foreach {
        reg delete "$($_.Name)" /f >$null 2>$null
    }
    Get-ChildItem "$store\Deleted\EndOfLife" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_ -like "*${i}*" } | foreach {
        reg delete "$($_.Name)" /f >$null 2>$null
    }
}
## extra cleanup
$desktop = [Environment]::GetFolderPath('Desktop')
$appdata = [Environment]::GetFolderPath('ApplicationData')
Remove-Item "$appdata\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$appdata\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue

## add OpenWebSearch to redirect microsoft-edge: anti-competitive links to the default browser
$IFEO = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
$MSEP = ($env:ProgramFiles, ${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application'
$MIN = ('--headless','--width 1 --height 1')[([environment]::OSVersion.Version.Build) -gt 25179]
$CMD = "$env:systemroot\system32\conhost.exe $MIN" # AveYo: minimize prompt - see Terminal issue #13914
reg add HKCR\microsoft-edge /f /ve /d URL:microsoft-edge >$null
reg add HKCR\microsoft-edge /f /v "URL Protocol" /d "" >$null
reg add HKCR\microsoft-edge /f /v NoOpenWith /d "" >$null
reg add HKCR\microsoft-edge\shell\open\command /f /ve /d "$DIR\ie_to_edge_stub.exe %1" >$null
reg add HKCR\MSEdgeHTM /f /v NoOpenWith /d "" >$null
reg add HKCR\MSEdgeHTM\shell\open\command /f /ve /d "$DIR\ie_to_edge_stub.exe %1" >$null
reg add "$IFEO\ie_to_edge_stub.exe" /f /v UseFilter /d 1 /t reg_dword >$null
reg add "$IFEO\ie_to_edge_stub.exe\0" /f /v FilterFullPath /d "$DIR\ie_to_edge_stub.exe" >$null
reg add "$IFEO\ie_to_edge_stub.exe\0" /f /v Debugger /d "$CMD $DIR\OpenWebSearch.cmd" >$null
reg add "$IFEO\msedge.exe" /f /v UseFilter /d 1 /t reg_dword >$null
reg add "$IFEO\msedge.exe\0" /f /v FilterFullPath /d "$MSEP\msedge.exe" >$null
reg add "$IFEO\msedge.exe\0" /f /v Debugger /d "$CMD $DIR\OpenWebSearch.cmd" >$null

[io.file]::WriteAllText("$DIR\OpenWebSearch.cmd", $OpenWebSearch) >$null
## cleanup
$cleanup = Get-ItemProperty 'Registry::HKEY_Users\S-1-5-21*\Volatile*' -Name Edge_Removal -ErrorAction SilentlyContinue
if ($cleanup) {
    Remove-ItemProperty $cleanup.PSPath Edge_Removal -Force -ErrorAction SilentlyContinue
}

Write-Host -NoNewline -ForegroundColor Green -BackgroundColor Black "`n EDGE REMOVED!"
