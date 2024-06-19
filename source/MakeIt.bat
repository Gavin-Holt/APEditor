@echo off & cls
REM Change to current batch file location
cd /D "%~dp0"

REM Compile APEditor 
Ahk2Exe.exe /in APEditor.ahk /out ..\APEditor.exe /icon img\APEditor.ico

REM Compile APRunner
Ahk2Exe.exe /in APRunner.ahk /out ..\APRunner.exe /icon img\APEditor.ico

REM Start
shelexec.exe /Params:%1 /EXE "..\APRunner.exe"
exit
