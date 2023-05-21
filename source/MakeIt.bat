@echo off
REM Change to current batch file location
cd /D "%~dp0"

REM Needs to run from temp to avoid OneDrive security sweep
copy ..\APE*.* "%temp%\*.*"
md %temp%\img
copy ..\img\*.* "%temp%\img\*.*"

REM Compile APEditor
REM The bin stub is already UPX compressed!
Ahk2Exe.exe /in APEditor.ahk /out %temp%\APEditor.exe /icon img\APEditor.ico

REM Compile APRunner
Ahk2Exe.exe /in APRunner.ahk /out %temp%\APRunner.exe /icon img\APEditor.ico

REM Start
shelexec.exe /Params:%1 /EXE "%temp%\APEditor.exe"
exit
