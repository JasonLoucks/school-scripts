@echo off

:: Save the launcher script's working directory
:: Change the working directory to this script's
:: - This is so we can use relative paths when running the ps1
set origDir=%CD%
cd /d "%~dp0"

:: Location of the CSCS ps1 script
set CSCS_ps1=..\powershell\CSCS.ps1

pwsh %CSCS_ps1%

:: Go back to the original working directory so we can run SetUserFTA
cd %origDir%

:: Locations of the SUFTA folder and files
set SUFTA=%~d0\PortableApps\SetUserFTA
set SUFTA_exe=%SetUserFTA%\SetUserFTA
set SUFTA_config=%SetUserFTA%\config.txt

%SUFTA_exe% %SUFTA_config%
Start.exe