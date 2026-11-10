@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deployment\01_Install_Dependencies.ps1"
if errorlevel 1 (echo. & echo Script failed. Review the error above.)
echo.
pause
