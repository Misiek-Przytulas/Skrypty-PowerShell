@echo off
setlocal
title Document Search v1.0
cd /d "%~dp0"
if errorlevel 1 (
    echo Cannot open the script folder.
    pause
    exit /b 1
)
if not exist "%~dp0Search-Documents.ps1" (
    echo Search-Documents.ps1 must be next to this launcher.
    pause
    exit /b 1
)
echo Document Search v1.0
echo Results and errors will remain visible in this window.
echo Type exit after the search to close PowerShell.
powershell.exe -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass -File "%~dp0Search-Documents.ps1"
if errorlevel 1 (
    echo PowerShell exited with an error.
    pause
)
endlocal
