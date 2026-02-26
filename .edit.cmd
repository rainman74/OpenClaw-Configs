@echo off & setlocal EnableDelayedExpansion

set "WD=%CD%"
set "ARGS="

for %%F in ("%WD%\*.md") do (
  set "ARGS=!ARGS! "%%~fF""
)

start "" notepad "%WD%\.openclaw\Linux\openclaw.json" "%WD%\.openclaw\Windows\openclaw.json" !ARGS! "%NASPATH%\OpenClaw\.openclaw\openclaw.json" "%APPPATH%\OpenClaw\.openclaw\openclaw.json"