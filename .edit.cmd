@echo off & setlocal EnableDelayedExpansion

:INIT
cd /d "%~dp0"

:MAIN
set "WD=%CD%"
set "ARGS="

for %%F in ("%WD%\*.md") do (
  set "ARGS=!ARGS! "%%~fF""
)

start "" notepad "%WD%\.openclaw\Linux\openclaw.json" "%WD%\.openclaw\Windows\openclaw.json" !ARGS! "%APPPATH%\OpenClaw\.openclaw\openclaw.json"

:END
exit /b
