@ECHO off
rem change codepage to allow nice graphics ;-)
chcp 65001
rem change colors to white on black background
color 07
rem resize window to proper size
mode con cols=80 lines=36
rem Change title bar name
title Add EXIF
rem Set all changes as local
setlocal

cls
echo [94m
echo          ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗        
echo          ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝        
echo          ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║███████╗        
echo          ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║╚════██║        
echo          ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝███████║        
echo           ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚══════╝        
echo [96m
echo  ██████╗ ███████╗██████╗ ██╗      ██████╗  █████╗ ████████╗███████╗██████╗ 
echo  ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
echo  ██║  ██║█████╗  ██████╔╝██║     ██║   ██║███████║   ██║   █████╗  ██████╔╝
echo  ██║  ██║██╔══╝  ██╔══██╗██║     ██║   ██║██╔══██║   ██║   ██╔══╝  ██╔══██╗
echo  ██████╔╝███████╗██████╔╝███████╗╚██████╔╝██║  ██║   ██║   ███████╗██║  ██║
echo  ╚═════╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
echo [97m
echo                         By Chris Titus Tech
echo                     Batch script by Build-0-Matic
echo.
echo.

rem Check OS version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo Detected Windows version: %version%
if %version% lss 10 goto OSCheckFail

:OnlineCheck
rem Check is website is online
echo Checking if website is available
>nul 2>&1 ping christitus.com &&set online=True ||set online=False
if %online% equ True echo Chris Titus' website is online
if %online% equ False goto Offline

rem Check if running as Admin
echo Administrative permissions required. Detecting permissions...

net session >nul 2>&1
if %errorLevel% equ 0 (
	goto Admin
) else (
	goto NotAdmin
)


:Admin
echo Success: Administrative permissions confirmed.
echo.
echo Downloading and Running Windows Debloater
powershell -Command "irm https://christitus.com/win | iex"
rem powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/winutil.ps1')}"
goto End

:NotAdmin
echo [91m
echo Failure: Current permissions inadequate.
echo.
echo Please run as Administrator.
pause
goto End

:Offline
echo [91m
echo Chris Titus' website is currently offline.
echo.
echo Verify that you have a proper internet connection and try again.
echo.
choice /m "(A)bort, (R)etry, (F)ail" /c arf
if errorlevel 3 goto Fail
if errorlevel 2 goto OnlineCheck
if errorlevel 1 goto end
exit

:OSCheckFail
echo [91m
echo Minimum Windows version required: 10
echo.
echo This script will now abort
pause
exit

:Fail
echo.
echo My internet router is in my basement.
echo You could say that I come from a LAN down under.
timeout 10
exit

:End
echo [92m
echo Thank you for using the Windows Debloater
echo.
echo Script will now exit
timeout 10
exit

