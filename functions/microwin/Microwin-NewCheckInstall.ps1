function Microwin-NewCheckInstall {

    # using here string to embedd firstrun
    $checkInstall = @'
    @echo off
    if exist "%HOMEDRIVE%\windows\cpu.txt" (
        echo %HOMEDRIVE%\windows\cpu.txt exists
    ) else (
        echo %HOMEDRIVE%\windows\cpu.txt does not exist
    )
    if exist "%HOMEDRIVE%\windows\SerialNumber.txt" (
        echo %HOMEDRIVE%\windows\SerialNumber.txt exists
    ) else (
        echo %HOMEDRIVE%\windows\SerialNumber.txt does not exist
    )
    if exist "%HOMEDRIVE%\unattend.xml" (
        echo %HOMEDRIVE%\unattend.xml exists
    ) else (
        echo %HOMEDRIVE%\unattend.xml does not exist
    )
    if exist "%HOMEDRIVE%\Windows\Setup\Scripts\SetupComplete.cmd" (
        echo %HOMEDRIVE%\Windows\Setup\Scripts\SetupComplete.cmd exists
    ) else (
        echo %HOMEDRIVE%\Windows\Setup\Scripts\SetupComplete.cmd does not exist
    )
    if exist "%HOMEDRIVE%\Windows\Panther\unattend.xml" (
        echo %HOMEDRIVE%\Windows\Panther\unattend.xml exists
    ) else (
        echo %HOMEDRIVE%\Windows\Panther\unattend.xml does not exist
    )
    if exist "%HOMEDRIVE%\Windows\System32\Sysprep\unattend.xml" (
        echo %HOMEDRIVE%\Windows\System32\Sysprep\unattend.xml exists
    ) else (
        echo %HOMEDRIVE%\Windows\System32\Sysprep\unattend.xml does not exist
    )
    if exist "%HOMEDRIVE%\Windows\FirstStartup.ps1" (
        echo %HOMEDRIVE%\Windows\FirstStartup.ps1 exists
    ) else (
        echo %HOMEDRIVE%\Windows\FirstStartup.ps1 does not exist
    )
    if exist "%HOMEDRIVE%\Windows\winutil.ps1" (
        echo %HOMEDRIVE%\Windows\winutil.ps1 exists
    ) else (
        echo %HOMEDRIVE%\Windows\winutil.ps1 does not exist
    )
    if exist "%HOMEDRIVE%\Windows\LogSpecialize.txt" (
        echo %HOMEDRIVE%\Windows\LogSpecialize.txt exists
    ) else (
        echo %HOMEDRIVE%\Windows\LogSpecialize.txt does not exist
    )
    if exist "%HOMEDRIVE%\Windows\LogAuditUser.txt" (
        echo %HOMEDRIVE%\Windows\LogAuditUser.txt exists
    ) else (
        echo %HOMEDRIVE%\Windows\LogAuditUser.txt does not exist
    )
    if exist "%HOMEDRIVE%\Windows\LogOobeSystem.txt" (
        echo %HOMEDRIVE%\Windows\LogOobeSystem.txt exists
    ) else (
        echo %HOMEDRIVE%\Windows\LogOobeSystem.txt does not exist
    )
    if exist "%HOMEDRIVE%\windows\csup.txt" (
        echo %HOMEDRIVE%\windows\csup.txt exists
    ) else (
        echo %HOMEDRIVE%\windows\csup.txt does not exist
    )
    if exist "%HOMEDRIVE%\windows\LogFirstRun.txt" (
        echo %HOMEDRIVE%\windows\LogFirstRun.txt exists
    ) else (
        echo %HOMEDRIVE%\windows\LogFirstRun.txt does not exist
    )
'@
    $checkInstall | Out-File -FilePath "$env:temp\checkinstall.cmd" -Force -Encoding Ascii
}
