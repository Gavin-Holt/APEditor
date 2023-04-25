@echo off
REM Change to current batch file location
cd /D "%~dp0"

REM The bin stub is already UPX compressed!


REM Move to temp
copy ..\APE*.* "%temp%\*.*"
md %temp%\img
copy ..\img\*.* "%temp%\img\*.*"
copy O:\MyProfile\cmd\GrepWin.exe  "%temp%\GrepWin.exe"
copy O:\MyProfile\cmd\ShelExec.exe "%temp%\ShelExec.exe"
copy O:\MyProfile\cmd\GetPlainText.exe "%temp%\GetPlainText.exe"
copy O:\MyProfile\cmd\TextDiff.exe "%temp%\TextDiff.exe"

REM dir %temp%\*.exe

REM Compile
Ahk2Exe.exe /in APEditor.ahk /out %temp%\APEditor.exe /icon img\APEditor.ico

REM Start
shelexec.exe /Params:%1 /EXE "%temp%\APEditor.exe"
exit
