#SingleInstance Off
#NoTrayIcon
DetectHiddenWindows, on
SetTitleMatchMode,2

vLine = %1%
StringSplit, vLine,vLine, @
vFileName 	:= vLine1
vLineNumber := vLine2

If WinExist("- APEditor")
{

    If FileExist(vFileName)
    {

        WinActivate
        Send !FO
        Sleep 1000
        SendRaw %vFileName%
    }
    Exitapp
}

If FileExist("O:\MyProfile\editor\conf2APE\APEditor.exe")
{
    Run, O:\MyProfile\editor\conf2APE\APEditor.exe "%vFileName%"
	ExitApp
}




