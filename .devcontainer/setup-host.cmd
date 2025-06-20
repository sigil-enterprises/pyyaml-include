@echo off
setlocal enabledelayedexpansion

REM Script to execute with bash
set "SCRIPT_TO_RUN=%~dp0setup-host"
set "BASH_EXECUTABLE="

echo Locating bash.exe to run %SCRIPT_TO_RUN%...

REM --- 1. Check if bash.exe is in PATH ---
echo Checking for bash.exe in system PATH...
for %%F_exe in (bash.exe) do (
  set "FOUND_IN_PATH=%%~$PATH:F_exe"
)

if defined FOUND_IN_PATH (
  if exist "%FOUND_IN_PATH%" (
    echo  [+] Found bash.exe in PATH: %FOUND_IN_PATH%
    set "BASH_EXECUTABLE=%FOUND_IN_PATH%"
  ) else (
    echo  [-] bash.exe reported in PATH but file does not exist: %FOUND_IN_PATH%
  )
) else (
  echo  [-] bash.exe not found directly in PATH.
)

REM --- 2. If not found in PATH, check common installation locations ---
if not defined BASH_EXECUTABLE (
  echo.
  echo Checking common Git for Windows installation locations...

  set "LOCATIONS_TO_CHECK="
  set "LOCATIONS_TO_CHECK=%LOCATIONS_TO_CHECK%;C:\Program Files\Git\bin\bash.exe"
  set "LOCATIONS_TO_CHECK=%LOCATIONS_TO_CHECK%;C:\Program Files (x86)\Git\bin\bash.exe"
  if defined LOCALAPPDATA (
    set "LOCATIONS_TO_CHECK=%LOCATIONS_TO_CHECK%;%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
  )
  if defined USERPROFILE (
     set "LOCATIONS_TO_CHECK=%LOCATIONS_TO_CHECK%;%USERPROFILE%\AppData\Local\Programs\Git\bin\bash.exe"
  )

  REM Remove leading semicolon if present from the list construction
  if defined LOCATIONS_TO_CHECK (
   if "!LOCATIONS_TO_CHECK:~0,1!"==";" set "LOCATIONS_TO_CHECK=!LOCATIONS_TO_CHECK:~1!"

   REM Iterate over the semicolon-separated list
   for %%L in ("!LOCATIONS_TO_CHECK:;=" "%") do (
     set "CURRENT_CHECK=%%~L"
     if defined CURRENT_CHECK (
       if exist "!CURRENT_CHECK!" (
         echo  [+] Found bash.exe at: !CURRENT_CHECK!
         set "BASH_EXECUTABLE=!CURRENT_CHECK!"
         goto :found_bash
       ) else (
         echo  [-] Not found at: !CURRENT_CHECK!
       )
     )
   )
  )
)

:found_bash
if defined BASH_EXECUTABLE (
  echo.
  echo Using bash: %BASH_EXECUTABLE%
  "%BASH_EXECUTABLE%" "%SCRIPT_TO_RUN%"
  set "BASH_EXIT_CODE=%ERRORLEVEL%"
  exit /b %BASH_EXIT_CODE%
)

REM --- 3. If not found, error out ---
echo.
echo ERROR: bash.exe was not found in your system PATH or common Git for Windows installation locations.
echo Please ensure Git for Windows (which includes Git Bash) is installed and accessible.
echo You can download it from https://git-scm.com/download/win
echo.
echo Attempted search locations:
echo  - System PATH
if defined LOCATIONS_TO_CHECK (
 for %%L in ("!LOCATIONS_TO_CHECK:;=" "%") do (
   set "CURRENT_DISPLAY=%%~L"
   if defined CURRENT_DISPLAY (
    echo  - !CURRENT_DISPLAY!
   )
 )
)
exit /b 1