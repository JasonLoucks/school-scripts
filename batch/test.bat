@echo off

set CSCS_ps1=%~d0\Documents\Scripting\test.ps1

set SUFTA=%~d0\PortableApps\SetUserFTA
set SUFTA_exe=%SetUserFTA%\SetUserFTA.exe
set SUFTA_config=%SetUserFTA%\config.txt

pwsh %CSCS_ps1% %msg%
rem %SUFTA_exe% %SUFTA_config%
rem Start.exe