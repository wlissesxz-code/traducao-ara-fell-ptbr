@echo off
setlocal
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Instalar.ps1"
if errorlevel 1 (
 echo.
 echo Nao foi possivel abrir o instalador. Consulte o LEIA-ME.txt.
 pause
)
