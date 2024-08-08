:: Ensure the script is running with administrative privileges
@echo off
fltmc >nul 2>&1 || (
	echo This script is not elevated!
	echo Requesting Admin permissions..
    PowerShell -Command "Start-Process PowerShell -ArgumentList 'Start-Process -Verb RunAs \"%~f0\"' -NoNewWindow " 2>nul || (
        >nul pause && exit /b 1
    )
    exit
)
