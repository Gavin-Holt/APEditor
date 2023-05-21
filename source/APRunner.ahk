#SingleInstance Off
#NoTrayIcon
DetectHiddenWindows, on
SetTitleMatchMode,2

If WinExist("- APEditor")
{
    pFileName = %1%
    If FileExist(pFileName)
    { 
;     	pFileName := "O:\MyProfile\editor\confAPE\source\ToDo.txt"
;     	ControlGet, hhEdit, Hwnd,, HiEdit1, - APEditor
; 		SendMessage, 2025, 0, &pFileName,, ahk_id %hhEdit%

        WinActivate
        Send !FO
        Sleep 1000
        SendInput %pFileName%
    }
    Exitapp
}

If FileExist(A_Temp "\APEditor.exe")
{
    Run, %A_Temp%\APEditor.exe "%1%"
	ExitApp
}

If FileExist("O:\MyProfile\editor\confAPE\source\MakeIt.bat")
{
	Run, O:\MyProfile\editor\confAPE\source\MakeIt.bat "%1%"
	ExitApp
}

