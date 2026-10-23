@echo off
setlocal
title Service Box - Logs Report
rem Configure all settings at the top of Get-ServiceBoxLogReport.ps1.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Get-ServiceBoxLogReport.ps1"
exit /b %errorlevel%
