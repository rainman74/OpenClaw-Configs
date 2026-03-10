@echo off & setlocal enabledelayedexpansion

:INIT
set FILE_L=openclaw.json
set FILE_M=Linux\openclaw.json
set FILE_R=Windows\openclaw.json
goto :MAIN

:MAIN
%APPPATH%\WinMerge\WinMergeU.exe "%FILE_L%" "%FILE_M%" "%FILE_R%"
goto :END

:END
exit /b
