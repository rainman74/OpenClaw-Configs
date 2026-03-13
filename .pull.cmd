@echo off & setlocal enabledelayedexpansion

:INIT
cd /d "%~dp0"

:MAIN
git pull

git submodule update --remote --merge

git add private_data
git commit -m "Bump submodule pointer" || echo Submodule already up to date.
git push

:END
exit /b
