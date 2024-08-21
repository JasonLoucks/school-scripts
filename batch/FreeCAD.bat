@echo off
set FreeCADDir=%cd%PortableApps\FreeCadPortable
set UserData=%FreeCADDir%\UserData
start %FreeCADDir%\bin\FreeCAD.exe -u %UserData%\user.cfg -s %UserData%\system.cfg