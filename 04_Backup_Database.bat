@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deployment\04_Backup_Database.ps1"
if errorlevel 1 (echo. & echo Script failed. Review the error above.)
echo.
pause
