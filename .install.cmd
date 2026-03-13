@echo off & setlocal enabledelayedexpansion

:INIT
cd /d "%~dp0"

:MAIN
if not exist "%APPPATH%\OpenClaw\workspace" exit /b 1

echo README.md > exclude.txt
echo private_data\>>exclude.txt

xcopy "*.md" "%APPPATH%\OpenClaw\workspace\" /s /y /exclude:exclude.txt

if exist "private_data\SOUL.md" copy /y "private_data\SOUL.md" "%APPPATH%\OpenClaw\workspace\SOUL.md"

del exclude.txt

:END
pause
exit /b
