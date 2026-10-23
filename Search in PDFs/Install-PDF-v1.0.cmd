@echo off
setlocal
title Document Search v1.0 - PDF Tools Installer
if not exist "%~dp0Install-PdfTools.ps1" (
    echo Install-PdfTools.ps1 must be next to this launcher.
    pause
    exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-PdfTools.ps1"
if errorlevel 1 (
    echo.
    echo Installation failed. Copy the error message from this window.
)
echo.
echo Press any key to close this window.
pause >nul
endlocal
