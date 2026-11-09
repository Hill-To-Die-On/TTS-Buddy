@echo off
setlocal
cd /d "%~dp0" || exit /b 1
node src/index.js --local %*
exit /b %errorlevel%
