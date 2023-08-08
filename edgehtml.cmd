@echo off
cd /d "%~dp0"
echo Uninstalling Microsoft Edge...
CLS
install_wim_tweak.exe /o /l
install_wim_tweak.exe /o /c Microsoft-Windows-Internet-Browser-Package /r
install_wim_tweak.exe /h /o /l
echo Microsoft Edge should be uninstalled. Please reboot Windows 10.
pause