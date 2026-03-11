@echo off & setlocal enabledelayedexpansion

:INIT
set FILE_L=Windows\openclaw.json
set FILE_R=D:\Apps\OpenClaw\.openclaw\openclaw.json

goto :MAIN

:MAIN
%APPPATH%\WinMerge\WinMergeU.exe "%FILE_L%" "%FILE_R%"
goto :END

:END
exit /b
