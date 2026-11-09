@echo off
setlocal
echo Starting TTS Buddy...
cd /d "%~dp0" || (
  echo Could not open the TTS Buddy folder.
  goto startup_error
)
if not exist "src\index.js" (
  echo Extract the entire ZIP, then open start-buddy.cmd from the extracted folder.
  goto startup_error
)
where.exe node.exe >nul 2>&1 || (
  echo Install Node.js 24 or newer, then launch Buddy again.
  goto startup_error
)

node.exe src/index.js --local %*
set "buddy_exit=%errorlevel%"
if "%buddy_exit%"=="0" exit /b 0
goto show_error

:startup_error
set "buddy_exit=1"

:show_error
echo(
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "if (-not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected) { Write-Host 'Press Enter to close.'; [void][Console]::ReadLine() }"
exit /b %buddy_exit%
