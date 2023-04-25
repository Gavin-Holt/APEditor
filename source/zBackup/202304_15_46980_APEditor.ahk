;# A Programmable Editor Gavin M Holt
; Standing upon the shoulders of giants, developed borrowing from various scripts:
; -	HiEdit.dll		Antonis Kyprianou (akyprian)
; -	HiEdit.ahk		Miodrag Milic (majkinetor ,miodrag.milic@gmail.com)
; -	HiEdit _test.ahk 	Magnetometer
; -	AHKPAd			Michael Peters
; -	QuickAHK		 (jballi)
; -	Vic	Editor		Normand Lamoureux (Normand)
;
; I have tried to avoid operations that load the whole file - preferring to process a line at a time,
; exceptions include:
; -	Block:			If you "select all" the whole file is in memory
; -	FileMenu_OpenTemplate:	Read whole file in then inserts
; -	EditMenu_FindREDown:	Reads the rest of the file before each search
; -	InsertMenu_File:	Reads whole file in then inserts

; Trying to allow multiple launches
ForceSingleInstance() 

;# Setup AHK Environment
#SingleInstance Off
#NoEnv
#NoTrayIcon
#MaxMem 128
SetWorkingDir, %A_ScriptDir%
AutoTrim,Off
SetBatchLines,-1
SetControlDelay,-1
SetWinDelay,-1
ListLines, Off
DetectHiddenWindows, On
SetTitleMatchMode,2
SendMode, Input
Process,Priority,,A
CoordMode, Mouse, Relative

;# GUI SETUP
Gui, +LastFound +Resize
$hwnd := WinExist()
Gui, font, s12, Consolas   ; This does not seem to work with the menu fonts

;# Toolbar with static pictures, and no tooltips, for speed!
Gui, Margin, 0,0
Gui, Add, Picture, HWNDToolBack x0 y0 w965 h44 BackgroundTrans,img/bluegrad.bmp
Gui, Add, Picture, gFileMenu_New x10 y6 BackgroundTrans, img/newbutton.png
Gui, Add, Picture, gFileMenu_OpenShortcut x50 y6 BackgroundTrans, img/openbutton.png
Gui, Add, Picture, gFileMenu_Save x90 y6 BackgroundTrans, img/savebutton.png
Gui, Add, Picture, x130 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gEditMenu_Cut x140 y6 BackgroundTrans, img/cutbutton.png
Gui, Add, Picture, gEditMenu_Copy x180 y6 BackgroundTrans, img/copybutton.png
Gui, Add, Picture, gEditMenu_Paste x220 y6 BackgroundTrans, img/pastebutton.png
Gui, Add, Picture, x260 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gEditMenu_Undo x270 y6 BackgroundTrans, img/undobutton.png
Gui, Add, Picture, gEditMenu_Redo x310 y6 BackgroundTrans, img/redobutton.png
Gui, Add, Picture, x350 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gBlockMenu_Indent x360 y6 BackgroundTrans, img/indentbutton.png
Gui, Add, Picture, gBlockMenu_Outdent x400 y6 BackgroundTrans, img/outdentbutton.png
Gui, Add, Picture, x440 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gEditMenu_Find x450 y7 BackgroundTrans, img/findbutton.png
Gui, Add, Picture, gEditMenu_FindRE x490 y7 w32 h32 BackgroundTrans, img/regexpbutton.png
Gui, Add, Picture, gEditMenu_Replace x530 y7 w32 h32 BackgroundTrans, img/replacebutton.png
Gui, Add, Picture, x570 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gFileMenu_Print x580 y7 BackgroundTrans, img/printbutton.png
Gui, Add, Picture, x620 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gToolsMenu_Shell x630 y7 BackgroundTrans, img/shellbutton.png
Gui, Add, Picture, gProjectMenu_Run x670 y6 w36 h36  BackgroundTrans, img/runbutton.png
Gui, Add, Picture, x710 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gFileMenu_Close x720 y7 BackgroundTrans, img/closebutton.png
Gui, Add, Picture, gEgg x760 y6 BackgroundTrans, img/sep.bmp

;# Menus
; Load menu before display for speed?
$MenuCreate()

; Default menu settings
Menu, FileMenu, Check, &Monitor
Menu, OptionsMenu, Check, &Line Numbers
Menu, OptionsMenu, Check, &Auto Indent

; Display menu
Gui, Menu, MyMenuBar

;# Statusbar
; Do I want one?

;# HiEdit
hEdit := HE_Add($hwnd,0,44,965,636, "HSCROLL VSCROLL HILIGHT TABBEDBOTTOM FILECHANGEALERT")
fStyle := "s18"
fFace  := "Consolas"
HE_SetFont(hEdit, fStyle "," fFace)
; #include hes/DarkColours.hes
#include hes/LightColours.hes
HE_SetColors(hEdit, colours)
HE_SetKeywordFile( "APEditor.hes")
HE_AutoIndent(hedit, true), $AutoIndent := true
HE_LineNumbersBar(hEdit, "automaxsize"), $LineNumbers := true

;# Show the whole application
Attach(hEdit, "w h")
Attach(ToolBack, "w")
Gui, Show, w965 h680, APEditor
Gui, Maximize

;# Timers
SetTimer, $SetTitle, 50

;# Load files from command line or Drag'n'Drop
; ToDo Do we need a loop to cope with multiple input files
Input = %1%
If Input
{
	$OpenFile(hEdit, Input)
} else {
    ; Set focus on *File1 for typing!
    ControlFocus, HiEdit1
}

; Set tab width now to make it work!
HE_SetTabWidth(hEdit,4)

;End of Autoexec Section: Defined by return/exit/hotkeys

;# Hotkeys
SetTitleMatchMode, 2
#IfWinActive ahk_class AutoHotkeyGUI

	^A::	$CMDCall("SelectMenu_All")
	^B::	Send {Home}
;	^C::	COPY
	^D::	$CMDCall("BlockMenu_Duplicate")
	^E::	Send {End}
	^F::	$CMDCall("EditMenu_Find")
	^G::	$CMDCall("EditMenu_GoTo")
	^H::	$CMDCall("EditMenu_Replace")
; 	^I::	$CMDCall("BlockMenu_Indent")
	^I::	$CMDCall("InsertMenu_Insertor")
	^J::	$CMDCall("")
	^K::	$CMDCall("EditMenu_DelEOL")
	^L::	$CMDCall("SelectMenu_LineDown")
	^M::	$CMDCall("EditMenu_Mark")
	^N::	$CMDCall("FileMenu_New")
	^O::	$CMDCall("FileMenu_OpenShortCut")
	^P::	$CMDCall("FileMenu_Print")
	^Q::	$CMDCall("BlockMenu_Comment")
	^R::	$CMDCall("FileMenu_Revert")
	^S::	$CMDCall("FileMenu_Save")
	^T::	$CMDCall("")
	^U::	$CMDCall("EditMenu_UnMark")
;	^V::	PASTE
	^W::	$CMDCall("FileMenu_Close")
;	^X::	CUT
	^Y::	$CMDCall("BlockMenu_Yank")
;	^Z::	UNDO

;	^+A::	All occurances for multi cursor editor
	^+B::	Send +{Home}
	^+C::	$CMDCall("EditMenu_CopyAppend")
	^+D::	$CMDCall("")
	^+E::	Send +{End}
	^+F::	$CMDCall("EditMenu_FindRE")
	^+G::	$CMDCall("EditMenu_Grep")
	^+H::	$CMDCall("EditMenu_ReplaceAll")
	^+I::	$CMDCall("")
	^+J::	$CMDCall("")
	^+K::	$CMDCall("EditMenu_DelBOL")
	^+L::	$CMDCall("SelectMenu_LineUp")
	^+N::	$CMDCall("")
	^+M::	$CMDCall("")
	^+O::   $CMDCall("")
	^+P::	$CMDCall("")
	^+Q::   $CMDCall("")
	^+R::	$CMDCall("")
	^+S::	$CMDCall("FileMenu_SaveAs")
	^+T::	$CMDCall("")
	^+U::	$CMDCall("")
	^+V::	$CMDCall("EditMenu_PastePlainText")
	^+W::	$CMDCall("")
	^+X::	$CMDCall("EditMenu_CutAppend")
	^+Y::   $CMDCall("")
	^+Z::	$CMDCall("EditMenu_Redo")

	^!A::	$CMDCall("")
	^!B::	$CMDCall("ProjectMenu_Backup")
	^!C::	$CMDCall("")
	^!D::	$CMDCall("ToolsMenu_Diff")
	^!E::	$CMDCall("")
	^!F:: 	$CMDCall("")
	^!G::	$CMDCall("")
	^!H::	$CMDCall("EditMenu_Replaceinfiles")
	^!I::	$CMDCall("InsertMenu_File")
	^!J::	$CMDCall("ProjectMenu_Jobs")
	^!K::	$CMDCall("")
	^!L::	$CMDCall("")
	^!M::	$CMDCall("ProjectMenu_MakeIt")
	^!N::	$CMDCall("")
	^!O::	$CMDCall("")
	^!P::	$CMDCall("")
	^!Q::	$CMDCall("")
	^!R::	$CMDCall("ProjectMenu_Run")
	^!S::	$CMDCall("")
	^!T::	$CMDCall("FileMenu_OpenTemplate")
	^!U::	$CMDCall("")
	^!V::	$CMDCall("FileMenu_ViewBackup")
	^!W::	$CMDCall("")
	^!X::	$CMDCall("")
	^!Y::   $CMDCall("")
	^!Z::   $CMDCall("")

    !W::	    $CMDCall("WindowsMenu_FileList")
    !SC02B::	$CMDCall("ProjectMenu_Folder")

    ^!SC02B::	$CMDCall("ToolsMenu_Shell")
	^=::		$CMDCall("ToolsMenu_Calculate")

	^SC027::	$CMDCall("PreMenu_1LineComment") ; ^;
	^SC02B::	$CMDCall("PreMenu_2LineComment") ; ^#
	^/::		$CMDCall("PreMenu_3LineComment") ; ^/
	^-::		$CMDCall("PreMenu_4LineComment") ; ^-
	^;::		$CMDCall("PreMenu_5LineComment") ; ^;
	^Space::	$CMDCall("PreMenu_ClearPrefix")

	^F1::	$CMDCall("")
	F5::	$CMDCall("")
	F9::	$CMDCall("")
	F10::	$CMDCall("")
	F11::	$CMDCall("")


	!Enter::	$CMDCall("InsertMenu_DateStamp")
	+Enter::	SendInput <br>
	; ^Enter::	Adds line below - see HiEditor defaults

;	^Right::	Word Right
;	^Left::		Word Left

	^TAB::	$CMDCall("WindowsMenu_NextTab")
	^+TAB::	$CMDCall("WindowsMenu_PrevTab")

;	Up::		Up
;	Down::		Down

	+Up::		$CMDCall("SelectMenu_LineUp")
	+Down::	    $CMDCall("SelectMenu_LineDown")

	^Up::		$CMDCall("EditMenu_FindUp")
	^Down::		$CMDCall("EditMenu_FindDown")

	^+Up::		$CMDCall("BlockMenu_ShiftUp")
	^+Down::	$CMDCall("BlockMenu_ShiftDown")

	!Left::		$CMDCall("EditMenu_GoBack")
	!Right::	$CMDCall("EditMenu_GoForward")

	+!Up::      $CMDCall("")
	+!Down::    $CMDCall("")

;	^DEL::		; 	Delete top next word
;	+DEL::		; 	BACKSPACE if not selection, ^X if there is a selection
;	^+DEL::	    ; 	Delete block

    ^BS::       Send +^{Left}{BS}

    ^WheelUp::   $CMDCall("FontInc")
    ^WheelDown:: $CMDCall("FontDec")

#IfWinActive

;# HiEdit Naviagtion Keys
; -	+{Right} 	Extend a selection one character to the right. SHIFT+RIGHT ARROW
; -	+{Left} 	Extend a selection one character to the left. SHIFT+LEFT ARROW
; -	+^{Right}	Extend a selection to the end of a word. CTRL+SHIFT+RIGHT ARROW NB To the next word including W
; -	+^{Left}	Extend a selection to the beginning of a word. CTRL+SHIFT+LEFT ARROW
; -	+{End}		Extend a selection to the end of a line. SHIFT+END
; -	+{Home}	    Extend a selection to the beginning of a line. SHIFT+HOME
; -	+{Down}     Over written see above	(Extend a selection one line down. SHIFT+DOWN ARROW)
; -	+{up}       Over written see above	(Extend a selection one line up. SHIFT+UP ARROW)
; -	+{PgDn}	    Extend a selection one screen down. SHIFT+PAGE DOWN
; -	+{PgUp}	    Extend a selection one screen up. SHIFT+PAGE UP
; -	+^{Home}	Extend a selection to the beginning of a document. CTRL+SHIFT+HOME
; -	+^{End}	    Extend a selection to the end of a document. CTRL+SHIFT+END
; -	^A			Extend a selection to include the entire document. CTRL+A
; -	^Enter		Adds a line below the cursor

;# Windows Global Keys
; - Avoid global windows keys

;# Command line processing
; https://www.autohotkey.com/board/topic/76240-single-instance-force-compiled-scripts-only/
ForceSingleInstance() {   
   global                                          
   local FirstInstancePID                          
   Process, Exist,%A_ScriptName%                   
   FirstInstancePID:=ErrorLevel                    
   if (FirstInstancePID=DllCall("GetCurrentProcessId")) { 
      return,OnMessage(0x4A,"Receive_WM_COPYDATA") 		; set the function that Get's the Commandline from 2... instances
   } else {                                          	; if not the first instance(2 instance or 3 ...)
      winshow,ahk_pid %FirstInstancePID% ahk_class AutoHotkeyGUI ; show the first window if hidden
      winactivate,ahk_pid %FirstInstancePID% ahk_class AutoHotkeyGUI ; Activate the first window 
      IfEqual,0,0,ExitApp                          		; Exit the second instance when ,no Parameter is passed
      Loop,%0%                                     		; Loop all commandlineitems
         args .= args ? "`n" %A_Index% : %A_Index% 		; put them in the string, separated by a newline
      Send_WM_COPYDATA(args,"ahk_pid" FirstInstancePID) ; send the arguments to the first instance
      exitapp                                      		; exit the second instance
      }
   }

Receive_WM_COPYDATA(wParam,lParam,Msg,hWnd ) {      	; Function to handle WM_COPYDATA Message(the messages send by other instances)
    global args                                     	; make the arguments accesable to the rest of the script
    WinGet, PPath, ProcessPath, ahk_id %hWnd%       	; Get the path of the app that send the message
    IfNotEqual,PPath,%A_ScriptFullPath%,Return,0    	; if the message is not from the second instance(the same app),Return
    args := StrGet(NumGet( lParam + 8 ))            	; Get the arguments
    Gosub,ParseCommandLine2Instance                 	; call our label
    Return,1                                        	; as to reply with a TRUE to Caller, ASAP
    }

Send_WM_COPYDATA(StringToSend,TargetScriptTitle) { 		; from the manual, onmessage (customized by me)
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)  	; Set up the structure's memory area.
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)  	; OS requires that this be done.
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)  ; Set lpData to point to the string itself.
    SendMessage, 0x4a, 0, &CopyDataStruct,, %TargetScriptTitle%  ; 0x4a is WM_COPYDATA. Must use Send not Post.
    return ErrorLevel  									; Return SendMessage's reply back to our caller.
	}
 
ParseCommandLine2Instance:
	msgbox,
	return
    
;# Menu Definitons
$MenuCreate(){

	Menu, FileMenu, Add, &New	Ctrl+N,MenuHandler
	Menu, FileMenu, Add, &Open...	Ctrl+O,MenuHandler
	Menu, FileMenu, Add, Rever&t	Ctrl+R,MenuHandler
	Menu, FileMenu, Add, &Close	Ctrl+W,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, Open Se&lection...	Ctrl+Shift+O,MenuHandler
	Menu, FileMenu, Add, Open &Template...	Ctrl+Alt+T,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Save	Ctrl+S,MenuHandler
	Menu, FileMenu, Add, Save &As...	Ctrl+Shift+S,MenuHandler
 	Menu, FileMenu, Add, Save A&ll,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, Save &Backup...	Ctrl+Alt+B,MenuHandler
	Menu, FileMenu, Add, &View Backup...	Ctrl+Alt+V,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Monitor,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, Print...	Ctrl+P,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, E&xit,	MenuHandler

	Menu, EditMenu, Add, &Undo	Ctrl+Z,MenuHandler
	Menu, EditMenu, Add, R&edo	Ctrl+Shift+Z,MenuHandler
	Menu, EditMenu, Add,
; 	Menu, EditMenu, Add, &Cut	Ctrl+X,MenuHandler
; 	Menu, EditMenu, Add, C&opy	Ctrl+C,MenuHandler
; 	Menu, EditMenu, Add, &Paste	Ctrl+V,MenuHandler
; 	Menu, EditMenu, Add,
	Menu, EditMenu, Add, Cut &Append	Ctrl+Shift+X,MenuHandler
	Menu, EditMenu, Add, Copy Appen&d	Ctrl+Shift+C,MenuHandler
	Menu, EditMenu, Add, Paste Plain &Text	Ctrl+Shift+V,MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Goto...	Ctrl+G,MenuHandler
	Menu, EditMenu, Add, Grep...	Ctrl+Shift+G,MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Mark	Ctrl+M,MenuHandler
	Menu, EditMenu, Add, Go &Back	Alt+Left,MenuHandler
	Menu, EditMenu, Add, Go &Forwards	Alt+Right,MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Find...	Ctrl+F,MenuHandler
	Menu, EditMenu, Add, FindR&E...	Ctrl+Shift+F,MenuHandler
	Menu, EditMenu, Add, Find in Files...	Ctrl+Alt+F,MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, Find Up	Ctrl+Up,MenuHandler
	Menu, EditMenu, Add, Find Down	Ctrl+Down,MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Replace...	Ctrl+H,MenuHandler
	Menu, EditMenu, Add, Replace A&ll...	Ctrl+Shift+H,MenuHandler
	Menu, EditMenu, Add, Replace in Files...	Ctrl+Alt+H,MenuHandler

	; Submenus for Block, must be defined first!

	Menu, TrimMenu, Add, &RTrim,MenuHandler
	Menu, TrimMenu, Add, &LTrim,MenuHandler
	Menu, TrimMenu, Add, &FullTrim,MenuHandler
	Menu, TrimMenu, Add, &EmptyLines,MenuHandler

	Menu, SortMenu, Add, &Ascending,MenuHandler
	Menu, SortMenu, Add, &Descending,MenuHandler
	Menu, SortMenu, Add, &Integer,MenuHandler
	Menu, SortMenu, Add
	Menu, SortMenu, Add, &Remove Dups,MenuHandler

	Menu, PreMenu, Add, &Bullet,MenuHandler
	Menu, PreMenu, Add, &Number,MenuHandler
	Menu, PreMenu, Add, &Renumber,MenuHandler
	Menu, PreMenu, Add
	Menu, PreMenu, Add, 1 `; Line Comment	Ctrl+`;,MenuHandler
	Menu, PreMenu, Add, 2 # Line Comment	Ctrl+#,MenuHandler
	Menu, PreMenu, Add, 3 // Line Comment	Ctrl+/,MenuHandler
	Menu, PreMenu, Add, 4 -- Line Comment	Ctrl+-,MenuHandler
	Menu, PreMenu, Add
	Menu, PreMenu, Add,  &Clear Prefix	Ctrl+Space,MenuHandler

	Menu, BlockMenu, Add, &Indent	TAB,MenuHandler
	Menu, BlockMenu, Add, &Outdent	+TAB,MenuHandler
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, &Duplicate	Ctrl+D,MenuHandler
	Menu, BlockMenu, Add, &Yank	Ctrl+Y,MenuHandler
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, Shift &Up	Ctrl+Up,MenuHandler
	Menu, BlockMenu, Add, Shift &Down	Ctrl+Down,MenuHandler
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, &Prefix,		:PreMenu
	Menu, BlockMenu, Add, &Sort, 		:SortMenu
	Menu, BlockMenu, Add, &Trim, 		:TrimMenu

    ; Submenus for Scripts, must be defined first!

	Menu, InsertMenu, Add, &Date,MenuHandler
	Menu, InsertMenu, Add, &Time,MenuHandler
	Menu, InsertMenu, Add, Date &Stamp	Ctrl+Enter,MenuHandler
	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, &File...	Ctrl+Alt+I,MenuHandler
	Menu, InsertMenu, Add, File &Name	Ctrl+Alt+N,MenuHandler
	Menu, InsertMenu, Add, &Get FileName..	Ctrl+Alt+G,MenuHandler
	Menu, InsertMenu, Add, Get &Rel FileName..	Ctrl+Alt+K,MenuHandler

	Menu, SelectMenu, Add, &All	Ctrl+A,MenuHandler
	Menu, SelectMenu, Add, Line&Down	Ctrl+L,MenuHandler
	Menu, SelectMenu, Add, Line&Up	Ctrl+Shift+L,MenuHandler
	Menu, SelectMenu, Add, &BOL	Ctrl+Shift+B,MenuHandler
	Menu, SelectMenu, Add, &EOL	Ctrl+Shift+E,MenuHandler

	Menu, FormatMenu, Add, &Upper Case,MenuHandler
	Menu, FormatMenu, Add, &Lower Case,MenuHandler
	Menu, FormatMenu, Add, &Reverse Case,MenuHandler
	Menu, FormatMenu, Add, &Proper Case,MenuHandler

	Menu, EOLMenu,Add, Win CRLF,MenuHandler
	Menu, EOLMenu,Add, Unix LF,MenuHandler
	Menu, EOLMenu,Add, Mac CR,MenuHandler

	Menu, ProjectMenu, Add, &Folder	Alt+#,MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, &Run	Ctrl+Alt+R,MenuHandler
	Menu, ProjectMenu, Add, &Makeit	Ctrl+Alt+M,MenuHandler
	Menu, ProjectMenu, Add, &Jobs	Ctrl+Alt+J,MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, &Backup	Ctrl+Alt+B,MenuHandler
	Menu, ProjectMenu, Add, &Versions	Ctrl+Alt+V,MenuHandler

	Menu, ToolsMenu, Add, &Calculate	Ctrl+=,MenuHandler
	Menu, ToolsMenu, Add, &Shell	Ctrl+Alt+#,MenuHandler
	Menu, ToolsMenu, Add, &Diff	Ctrl+Alt+D,MenuHandler

	Menu, ScriptsMenu, Add, &Select,		:SelectMenu
	Menu, ScriptsMenu, Add, &Insert,		:InsertMenu
	Menu, ScriptsMenu, Add,
	Menu, ScriptsMenu, Add, C&hange Case,	:FormatMenu
	Menu, ScriptsMenu, Add, Convert &EOL,	:EOLMenu
	Menu, ScriptsMenu, Add,
    Menu, ScriptsMenu, Add, &Project,       :ProjectMenu
    Menu, ScriptsMenu, Add, &Tools,       :ToolsMenu

    ; Submenus for Options, must be defined first!

	Menu, OptionsMenu, Add, &Font,MenuHandler
	Menu, OptionsMenu, Add, &Tabs,MenuHandler
	Menu, OptionsMenu, Add, &Colours,MenuHandler
	Menu, OptionsMenu, Add, Syta&x Colours,MenuHandler
	Menu, OptionsMenu, Add
	Menu, OptionsMenu, Add, &Line Numbers,MenuHandler
	Menu, OptionsMenu, Add, &Auto Indent,MenuHandler
	Menu, OptionsMenu, Add
	Menu, OptionsMenu, Add, F&ull Screen,MenuHandler

	Menu, WindowsMenu, Add, Next Tab	Ctrl+TAB,MenuHandler
	Menu, WindowsMenu, Add, Prev Tab	Ctrl+Shift+TAB,MenuHandler
	Menu, WindowsMenu, Add, &File List	Alt+W,MenuHandler

	Menu, HelpMenu, Add, &ToDo,MenuHandler
	Menu, HelpMenu, Add
	Menu, HelpMenu, Add, &Contents,MenuHandler
	Menu, HelpMenu, Add, &Menus,MenuHandler
	Menu, HelpMenu, Add, &Keys,MenuHandler
	Menu, HelpMenu, Add
	Menu, HelpMenu, Add, &About,MenuHandler

	Menu, MyMenuBar, Add,&File,			:FileMenu
	Menu, MyMenuBar, Add,&Edit,			:EditMenu
	Menu, MyMenuBar, Add,&Block,		:BlockMenu
	Menu, MyMenuBar, Add,&Scripts,		:ScriptsMenu
	Menu, MyMenuBar, Add,&Options,		:OptionsMenu
	Menu, MyMenuBar, Add,&Windows,	    :WindowsMenu
	Menu, MyMenuBar, Add,&Help,		    :HelpMenu
	Menu, MyMenuBar, Color,  FFFFFFFF
}

;# Functions

MenuHandler:
	; Uses the name of the menu and item to call a subroutine,
	; after clearing out unwanted menu formatting
	MenuLabel = %A_ThisMenu%_%A_ThisMenuItem%
	StringSplit, MenuLabel,MenuLabel, %A_Tab%
	MenuLabel := MenuLabel1
	MenuLabel := RegExReplace(MenuLabel, "&" , "")
	MenuLabel := RegExReplace(MenuLabel, ";" , "")
	MenuLabel := RegExReplace(MenuLabel, "#" , "")
	MenuLabel := RegExReplace(MenuLabel, " " , "")
	MenuLabel := RegExReplace(MenuLabel, "\." , "")
	MenuLabel := RegExReplace(MenuLabel, "/" , "")
	MenuLabel := RegExReplace(MenuLabel, "-" , "")
	Gosub, $GetFilePath
	Gosub, %MenuLabel%
	return

$CMDCall(CMD){
	;Some commands can't call gosub, they need to call a function!
	Gosub, $GetFilePath ; Not sure if these variables are set as global
	Gosub, %CMD%
}

$GetFilePath:
	;Designed to create global variables MyFilePath MyFileName (Name.ext)
	fn := HE_GetFileName(hEdit,-1)

	If (FileExist(fn)) {
		Loop, %fn%
		{
			MyFilePath = %A_LoopFileDir%
			MyFileName = %A_LoopFileName%
			MyFileExt = %A_LoopFileExt%
			; FullPath = %MyFilePath%\%MyFileName%
			; Global MyFilePath MyFileName MyFileExt
		}
	} Else {
			MyFilePath =
			MyFileName =
			MyFileExt =
	}
	return

$SetTitle: ; SetTimer won't call a function!
	$SetTitle(hEdit,$hwnd)
	return

$SetTitle(hEdit,$hwnd){
	if HE_GetModify(hEdit, idx=-1) {
		pre = *
		}
	fn:=HE_GetFileName(hEdit,-1)
	WinSetTitle,ahk_id %$hwnd%,,%pre%%fn% - APEditor
	return
}

;# Command subroutines

Egg:
	MsgBox,48,"Easter Egg","OK, now I have egg on my face!"
	return

FileMenu_New:
	HE_NewFile(hEdit)
	return

FileMenu_OpenShortCut:
	; If a filename in the text is selected open it!
	Sel := HE_GetSelText(hEdit)
	If (FileExist(Sel) and InStr(FileExist(Sel), "D")=0 ){
		$OpenFile(hEdit, Sel)
	} Else {
		Sel := MyFilePath . "\" . Sel
		If (FileExist(Sel) and InStr(FileExist(Sel), "D")=0 ){
			$OpenFile(hEdit, Sel)
		} Else {
		    $CMDCall("FileMenu_Open")
		}
	}
	return

FileMenu_Open:
	FileSelectFile, fn, 3, %MyFilePath% , Open a file
	if Errorlevel
		return
	$OpenFile(hEdit, fn)
	return

FileMenu_OpenTemplate:
	FileSelectFile, fn, 3, %A_ScriptDir%\..\templates\, Open a generic template
	If Errorlevel {
		FileSelectFile, fn, 3, %MyFilePath%\_Template\, Open a local template
		If Errorlevel {
			return
		}
	}

	HE_NewFile(hEdit)
	FileRead, iText, %fn%
	$SendText(hEdit,iText)
	return

FileMenu_Save:
	If FileExist(HE_GetFileName(hEdit)){
		HE_SaveFile(hEdit, HE_GetFileName(hEdit))
		HE_SetModify(hEdit, 0)
		$SetTitle(hEdit,$hwnd)

        ; Record history
        MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit)) + 1
        FileAppend , %fn%@%MyLineNumber%`n , %A_ScriptDir%\APEditor.his

	} Else {
		$CMDCall("FileMenu_SaveAs")
	}
	return

FileMenu_SaveAs:
	FileSelectFile, fn, S 16, %MyFilePath% , Save File As..
	if (Errorlevel)
		return
	HE_SaveFile(hEdit, fn, -1)
	HE_SetModify(hEdit, 0)
	$SetTitle(hEdit,$hwnd)
    ; Record history
    MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit)) + 1
    FileAppend , %fn%@%MyLineNumber%`n , %A_ScriptDir%\APEditor.his
	return

FileMenu_SaveAll:
	nFiles := HE_GetFileCount(hEdit)
	Loop,%nFiles%
	{
		$CMDCall("FileMenu_Save")
		$CMDCall("WindowsMenu_NextTab")
	}
	Gosub, $GetFilePath ; Get back the correct file / path
	return

FileMenu_SaveSelection:
	HE_Copy(hEdit)
	HE_NewFile(hEdit)
	HE_Paste(hEdit)
	$CMDCall("FileMenu_SaveAs")
	return

FileMenu_Monitor:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	; ToDo FileMenu_Monitor - this is already set but I have no event call back function
	return

FileMenu_Revert:
	HE_ReloadFile(hEdit)
	return

FileMenu_Print:
	HE_Print(hEdit)
	Return

FileMenu_Close:
	If HE_GetModify(hEdit,-1)
	{
		$FileName :=  HE_GetFileName(hEdit)
		msgbox,  3, APEditor - File not saved , Save changes to %$FileName% ?
		IfMsgBox, Yes
 			$CMDCall("FileMenu_Save")
        IfMsgBox, Cancel
            Return
	}
    If HE_GetFileCount(hEdit) > 1
	{
        HE_CloseFile(hEdit, -1)
    } Else {
        HE_CloseFile(hEdit, -1)
        ExitApp
    }
	return

FileMenu_Exit:
	; Link to here from GUIExit and OnExit
	nFiles := HE_GetFileCount(hEdit)
	Loop,%nFiles%
	{
		$CMDCall("FileMenu_Close")
	}
	; This is where save preferences would go
	ExitApp
	return

EditMenu_Undo:
	HE_Undo(hEdit)
	return

EditMenu_Redo:
	HE_Redo(hEdit)
	return

EditMenu_Cut:
	HE_Cut(hEdit)
	return

EditMenu_Copy:
	HE_Copy(hEdit)
	return

EditMenu_Paste:
	HE_Paste(hEdit)
	return

EditMenu_PastePlainText:
	Runwait, "getplaintext.exe"
	HE_Paste(hEdit)
	return

EditMenu_CutAppend:
	Sel:=HE_GetSelText(hEdit)
	If (StrLen(Sel)<1)
		 Return
	Clipboard:=Clipboard . Sel
	; Now clear the selection
	HE_Clear(hEdit)
	return

EditMenu_CopyAppend:
	Sel:=HE_GetSelText(hEdit)
	If (StrLen(Sel)<1)
		 Return
	Clipboard:=Clipboard . Sel
	return

EditMenu_DelEOL:
    ; ToDo EditMenu_DelEOL
    send +{End}
    Sel:= HE_GetSelText(hEdit)
    StrLen(Sel)
	If StrLen(Sel)>1
	{
		send {Del}
	}
    return

EditMenu_DelBOL:
    ; ToDo EditMenu_DelEOL
    send +{Home}
    Sel:= HE_GetSelText(hEdit)
    StrLen(Sel)
	If StrLen(Sel)>1
	{
		send {Del}
	}
    return

EditMenu_Goto:
	Sel:= HE_GetSelText(hEdit)
	cnt := HE_GetLineCount(hEdit)
	; Ask for line number - modal dialog
	Gui, +OwnDialogs
	InputBox, line, Go To Line, Enter line number or function name, , 400, 125, , , , ,%Sel%
	If ErrorLevel
		return

	If line is integer
	{
		If (line > cnt) {
			line := cnt
		}
		$GotoLine(hEdit, line)
		return
	}

	If line is not integer
	{
		FindText := line
		MyLastFind := "RE"
		GoSub, EditMenu_FindDown
	}

	return

EditMenu_Grep:
    ; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	} Else {
		FindText := Sel
	}

	Run, GrepWin.exe /portable /searchpath:"%MyFilePath%" /filemask:"%MyFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
    return

EditMenu_Mark:
    MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit)) + 1
    If (LocStack%Pointer% != MyLineNumber)
    {
        Pointer++
        LocStack%Pointer% := MyLineNumber
    }
	return

EditMenu_GoBack:
	; Stored in a variable - sorry another global pointer!!
    If (Pointer<1) {
        return
    }
    If (LocStack%Pointer% < 1 ) {
        return
    }
    If (LocStack%Pointer% > HE_GetLineCount(hEdit) ) {
        return
    }

    ; Get current location
    MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit)) + 1

    ; Search back for a different location
    While (LocStack%Pointer% = MyLineNumber){
        Pointer--
        If (Pointer=0) {
            Pointer++
            Break
        }
    }

    ; Goto to location
    If (Pointer>=1) {
        $GotoLine(hEdit, LocStack%Pointer%)
    }
    return

EditMenu_GoForward:
	; Stored in a variable - sorry another global pointer!!

    ; Check if any stored locations
    If (Pointer<1) {
        return
    }
    ; Check if current location is valid
    If (LocStack%Pointer% < 1 ) {
        return
    }
    If (LocStack%Pointer% > HE_GetLineCount(hEdit) ) {
        return
    }

    ; Get current location
    MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit)) + 1

    ; Search forward for a different location
    While (LocStack%Pointer% = MyLineNumber) {
        P2 := Pointer + 1
        If not (LocStack%P2%) {
            return
        } Else {
            Pointer++
        }
    }

    ; Goto to location
    $GotoLine(hEdit, LocStack%Pointer%)
    return

EditMenu_Find:
	; Gosub, $GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel := HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel := ""
	}

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, FindText, Find Text, Enter search text, , 400, 125, , , , ,%Sel%
	if ErrorLevel
		return

	; Default to looking downwards
	; I really don't like creating a state ... but
	MyLastFind := "Text"
	GoSub, EditMenu_FindDown
	return

EditMenu_FindRE:
	; Gosub, $GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	}

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, FindText, Find RegEx, Enter regular expression, , 400, 125, , , , ,%Sel%
	if ErrorLevel
		return

	; I really don't like creating a state ... but
	MyLastFind := "RE"
	; Default to looking downwards
	GoSub, EditMenu_FindREDown
	return

EditMenu_FindUp:
	If (MyLastFind = "RE") {
		GoSub, EditMenu_FindREUp
	}
	If (MyLastFind = "Text") {
		GoSub, EditMenu_FindTUp
	}
	return

EditMenu_FindDown:
	If (MyLastFind = "RE") {
		GoSub, EditMenu_FindREDown
	}
	If (MyLastFind = "Text") {
		GoSub, EditMenu_FindTDown
	}
	return

EditMenu_FindTUp:
	; Get current file position
	fp := HE_GetSel(hEdit)

	; Find the previous occurence
	nfp := HE_FindText(hEdit, FindText, fp, 0, Flags)

	if nfp >= 4294967295		; End of file
	{
		msgbox, 8196, Search again? , Top of file - start at the end?
			IfMsgBox, No
				exit
			IfMsgBox, Yes
			{
				fl := HE_GetTextLength(hEdit)
				nfp := HE_FindText(hEdit, FindText, fl , 0, Flags)
				if nfp = 4294967295
				{
					msgbox, 8240, String not found!, % FindText . " "
					FindText := "" ; To stop Replace All
					exit
				}
			}
	}

	; Highlight found text
	HE_SetSel(hEdit, nfp, nfp + StrLen(FindText) )
	HE_ScrollCaret(hEdit)
	return

EditMenu_FindTDown:
	; Get current file position
	fp := HE_GetSel(hEdit)

	; Move on if this is the search term
	Sel := HE_GetSelText(hEdit)
	If (Sel = FindText) {
		fp := fp + StrLen(FindText)
	}

	; Find the next occurence
	nfp := HE_FindText(hEdit, FindText, fp, -1, Flags)

	; Deal with end of file
	if nfp >= 4294967295
	{
		msgbox, 8196, Search again? , End of file - start at the top?
			IfMsgBox, No
				exit
			IfMsgBox, Yes
			{
				nfp := HE_FindText(hEdit, FindText, 0, -1, Flags)
				if nfp = 4294967295
				{
					msgbox, 8240, String not found!, % FindText . " "
					FindText := ""  ; To stop Replace All
					exit
				}
			}
	}

	; Highlight found text
	HE_SetSel(hEdit, nfp, nfp + StrLen(FindText) )
	HE_Scroll(hEdit,1,0)
	HE_ScrollCaret(hEdit)
	return

EditMenu_FindREUp:
	msgbox, Can't do RE find upwards -yet, Sorry
	return

EditMenu_FindREDown:
	; EditMenu_FindREDown  - does not allow ^ or $ with P)
	; Get current file position
	fp := HE_GetSel(hEdit)

	; Allow for previous find
	If (REMatchLen > 0 ){
		fp := fp + REMatchLen
	}

	; Add options to return found position
	REFindText := "P)" . FindText

	; If necessary allow multiline
	If (InStr(REFindText, "^")  or InStr(REFindText, "$") or InStr(REFindText, "\R") or InStr(REFindText, "\n") or InStr(REFindText, "\r")){
		StringReplace, REFindText, REFindText, P`) , Pm`)
		msgbox, %REFindText%
	}

	; Select all text below
	MyText := HE_GetTextRange(hEdit)

	; Find the next occurence
	nfp := RegExMatch(MyText, REFindText, REMatchLen, fp)

	if (nfp >= 4294967295 or nfp = 0)
	{
		msgbox, 8196, Search again? , End of file - start at the top?
			IfMsgBox, No
				exit
			IfMsgBox, Yes
			{
				nfp := RegExMatch(MyText, REFindText, REMatchLen, 1)
				if ErrorLevel {
					msgbox, 8240, RE not found!, % FindText . " "
					FindText := ""  ; To stop Replace All
					exit
				}
			}
	}

	; Highlight found text
	HE_SetSel(hEdit, nfp -1, nfp + REMatchLen -1)
	HE_Scroll(hEdit,1,0)
	HE_ScrollCaret(hEdit)
	return

EditMenu_FindinFiles:
	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	} Else {
		FindText := Sel
	}

	Run, GrepWin.exe /portable /searchpath:"%MyFilePath%" /filemask:"*.*" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
	return

EditMenu_Replace:
	; Gosub, $GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Target:= Sel
		ReplaceText:=""
        ReplaceCMD := Sel . "|"
	} Else {
		ReplaceText:= Sel
		Target:=""
        ReplaceCMD := Sel . "|"
	}

	; Loop back point
	ReplaceLoop:

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, ReplaceCMD, Replace Text, <find_str>|<replace_str>, , 400, 125, , , , ,%ReplaceCMD%
	if ErrorLevel
		return

	; Split the command string
	RepArray1 := ""
	RepArray2 := ""
	RepArray3 := ""
	StringSplit, RepArray, ReplaceCMD ,|
	FindText 	:= RepArray1
	ReplaceText	:= RepArray2
	ReplaceOptions	:= ""

	; Check commands
	If (RepArray0 < 2){
		msgbox, Too few parameters
		return
	}
	If (FindText=""){
		msgbox, No string to find
		return
	}
	If (ReplaceText=""){
		msgbox, No replacement string
		return
	}
	If (FindText = HE_GetSelText(hEdit)){
		;do the replacement
		Send, %ReplaceText%
	}

	; If no options then do one at a time - ? loop back after displaying next find
	If (ReplaceOptions="") {
		MyLastFind := "Text"
		GoSub, EditMenu_FindDown
		Goto, ReplaceLoop
	}

	return

EditMenu_ReplaceAll:
	; Gosub, $GetFilePath ; If called from the toolbar we will miss these instructions

	; Remember the current`position
	CurrChar := HE_LineIndex(hEdit, -1)

	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Target:= Sel
		ReplaceText:=""
        ReplaceCMD := Sel . "|"
	} Else {
		ReplaceText:= Sel
		Target:=""
        ReplaceCMD := Sel . "|"
	}

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, ReplaceCMD, Replace All, <find_str>|<replace_str>, , 400, 125, , , , ,%ReplaceCMD%
	if ErrorLevel
		return

	; Split the command string
	RepArray1 := ""
	RepArray2 := ""
	RepArray3 := ""
	StringSplit, RepArray, ReplaceCMD ,|
	FindText 	:= RepArray1
	ReplaceText	:= RepArray2
	ReplaceOptions	:= "All"

	; Check commands
	If (RepArray0 < 2){
		msgbox, Too few parameters
		return
	}
	If (FindText=""){
		msgbox, No string to find
		return
	}
	If (ReplaceText=""){
		msgbox, No replacement string
		return
	}
	If (FindText = HE_GetSelText(hEdit)){
		;do the replacement
		Send, %ReplaceText%
	}

	If (ReplaceOptions="All" or ReplaceOptions="all"  or ReplaceOptions="ALL"){
		If (Target="") {
			; ToDo Problem getting it to select whole document
			HE_SetSel(hEdit, 0, -1)
			Target := HE_GetSelText(hEdit)
			StringReplace, Output, Target, %FindText%, %ReplaceText%, All
			HE_ReplaceSel(hEdit,Output)
            ; ToDo EditMenu_ReplaceAll. Do we need to reposition cursor?
		} Else {
			StringReplace, Output, Target, %FindText%, %ReplaceText%, All
			HE_ReplaceSel(hEdit,Output)
		}
	}

    ; Restore position
    HE_SetSel(hEdit,CurrChar,CurrChar)
	HE_ScrollCaret(hEdit)
	return

EditMenu_Replaceinfiles:
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	} Else {
		FindText := Sel
	}

	$CMDCall("FileMenu_Save")
	Gosub, WinDisable
	Runwait, GrepWin.exe /portable /searchpath:"%MyFilePath%" /filemask:"%MyFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
	Gosub, WinEnable
	Gosub, FileMenu_Revert
	return

SelectMenu_BOL:
	send +{Home}
	return

SelectMenu_EOL:
	send +{End}
	return

SelectMenu_LineDown:
	HE_GetSel(hEdit,BlockStart,BlockEnd)
	CaretLine := HE_LineFromChar(hedit,HE_LineIndex(hedit,-1))
	StartLine := HE_LineFromChar(hEdit,BlockStart)
	EndLine:= HE_LineFromChar(hEdit,BlockEnd)
	; I'm not sure all these are used:)
	If (StartLine = EndLine){
		;Selection on one line
		Send {Home}
		Send +{End}
		Send +{Right}
		return
	}
	If (CaretLine = EndLine){
		; Selection is on this line
		Send +{End}
		; Need to move it on next time
		Send +{Right}
		Send +{End}
		return
	}
	If (CaretLine < EndLine){
		; We where selecting upwards and need to unselect
		Send +{End}
		Send +{Right}
		return
	}
	msgbox, Error: C %CaretLine% S %StartLine% E %Endline%
	return

SelectMenu_LineUp:
	HE_GetSel(hEdit,BlockStart,BlockEnd)
	CaretLine := HE_LineFromChar(hedit,HE_LineIndex(hedit,-1))
	StartLine := HE_LineFromChar(hEdit,BlockStart)
	EndLine:= HE_LineFromChar(hEdit,BlockEnd)
	; I'm not sure all these are used:)
	If (StartLine = EndLine){
		;Selection on one line
		Send {End}
		Send +{Home}
		If (BlockStart = HE_LineIndex(hedit,-1)){
			Send +{Left}
			Send +{Home}
		}
		return
	}
	If (CaretLine = EndLine){
		;  We were selecting downwards and need to unselect
		Send +{End}
		Send +{Home}
		Send +{Left}
		return
	}
	If (CaretLine = StartLine){
		;  We were selecting upwards and need to continue
		Send +{Left}
		Send +{Home}
		return
	}
	If (CaretLine < EndLine){
		; We are selecting upwards and need to extend
		Send +{Home}
		Send +{Left}
		Send +{Home}
		return
	}
	msgbox, Error: C %CaretLine% S %StartLine% E %Endline%
	return

SelectMenu_All:
	HE_SetSel(hEdit, 0, -1)
	return

FormatMenu_UpperCase:
	HE_ConvertCase(hEdit,"upper")
	return

FormatMenu_LowerCase:
	HE_ConvertCase(hEdit,"lower")
	return

FormatMenu_ProperCase:
	HE_ConvertCase(hEdit,"capitalize")
	return

FormatMenu_ReverseCase:
	HE_ConvertCase(hEdit)
	return

EOLMenu_UnixLF:
	;ToDo EOLMenu_UnixLF
	return

EOLMenu_MacCR:
	;ToDo EOLMenu_MacCR
	return

EOLMenu_WinCRLF:
	; Remember the current`position
	CurrChar := HE_LineIndex(hEdit, -1)

	; Break types - created outside the Loop!
	HardBreak 	:= Chr(13) . Chr(10)		; CRLF 	`r`n
	SoftBreak 	:= Chr(10)				    ; LF		`n
	EOF			:= ""                       ; Can't make Chr(0) . Chr(0)

	; Loop through the whole file testing the EOL
	$Index := 1
	While ($Index < HE_GetLineCount(hEdit) ){
		Text 		:= HE_GetLine(hEdit, $Index-1)
		FirstChar 	:= HE_LineIndex(hEdit, $Index-1)
		LastChar 	:= FirstChar + HE_LineLength(hEdit, $Index-1)

		; Get the next two chars to see what type of EOL characters are present
		NextChar	:= HE_GetTextRange(hEdit, LastChar, LastChar+2)
		If (NextChar = HardBreak)
		{
			;
		}
		Else If (SubStr(NextChar, 1 , 1) = SoftBreak)
		{
			; Add hardbreak
			Text := Text . HardBreak
			; Change text and redisplay - so we can harvest the next two chars
			; the +1 stops duplication of the last char - can't work out why!
			HE_SetSel(hEdit,FirstChar,LastChar+1)
			HE_ReplaceSel(hEdit, Text)

			; Get back to left hand edge - can't kill autoscroll
			HE_SetSel(hEdit,FirstChar,FirstChar)
			HE_ScrollCaret(hEdit)
		}
		Else If (NextChar = EOF)
		{
			; This is here to identify EOF - we should not get here
			msgbox, %$Index%   -  this is an EOF break
		}
		Else
		{
			; Unknown EOL - we should not get here
			msgbox, % $Index   "-  this is an  unknown EOL code: " Asc(SubStr(NextChar, 1 , 1) ) A_Space Asc(SubStr(NextChar, 2 , 1) )
		}

		; Increment counter
		$Index++
	}
    ; Restore position
	HE_SetSel(hEdit,CurrChar,CurrChar)
	HE_ScrollCaret(hEdit)
	return

InsertMenu_File:
	FileSelectFile, ifn, 3, %MyFilePath%, Insert file contents
	FileRead, iText, %ifn%
	$SendText(hEdit,iText)
	return

InsertMenu_Date:
	FormatTime,date,YYYYMMDDHH24MISS,dd-MM-yyyy
	$SendText(hEdit,date)
	return

InsertMenu_Time:
	FormatTime,time,YYYYMMDDHH24MISS,HH':'mm
	$SendText(hEdit,time)
	return

InsertMenu_DateStamp:
	FormatTime,date,YYYYMMDDHH24MISS,yyyy-MM-dd
	FormatTime,time,YYYYMMDDHH24MISS,HH':'mm
	$SendText(hEdit,date . " " . time . " ")
	return

InsertMenu_FileName:
	Sendinput, % HE_GetFileName(hEdit)
	return

InsertMenu_GetFileName:
	FileSelectFile, ifn, 3, MyFilePath, Get file name
	Sendinput, % ifn
	return

InsertMenu_GetRelFileName:
	FileSelectFile, ifn, 3, MyFilePath, Get file name
	ifn := $GetRelPath(HE_GetFileName(hEdit,-1),ifn)
	Sendinput, % ifn
	return

BlockMenu_Indent:
	Send {Tab}
	Gosub, $GetBlock
	return

BlockMenu_Outdent:
	Gosub, $GetBlock
	Send +{Tab}
	return

BlockMenu_Duplicate:
	Gosub, $GetBlock
	Send {Down}{Home}{Enter}{Up}
	Gosub, $SendBlock
	return

BlockMenu_Yank:
	Gosub, $GetBlock
	Send {Del}
	Send {Del}
	Return

BlockMenu_Join:
	Gosub, $GetBlock
	If (Block="") {
		return
	}
	Send, {DEL}
	HardBreak 	:= Chr(13) . Chr(10)
	If (InStr(Block, HardBreak)){
		Block := RegExReplace(Block,HardBreak," ")
		Block := RegExReplace(Block,"  "," ")
		Send {End}
	}
	Gosub, $SendBlock
	return

BlockMenu_ShiftUp:
	Gosub, $GetBlock
	SendInput {Del}{Del}{Up}{Enter}{Up}
	Gosub, $SendBlock
	return

BlockMenu_ShiftDown:
	Gosub, $GetBlock
	SendInput {Del}{Del}{Down}{Enter}{Up}
	Gosub, $SendBlock
	return

BlockMenu_Comment:
	Gosub, $GetBlock
	Block := "/*" . A_Tab . Block . A_Tab . "*/"
	Gosub, $SendBlock
    return

BlockMenu_BlockComment:
	Gosub, $GetBlock
    ; This needs to know prefix by filetype
    Block := RegExReplace(Block,"m)^.","; $0")
	Gosub, $SendBlock
	return

PreMenu_Bullet:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^.","-	$0")
	Gosub, $SendBlock
	return

PreMenu_Number:
	Gosub, $GetBlock
	MyCount = 1
	While (MyCount > 0){
		Block := RegExReplace(Block,"m)^[a-zA-Z]", MyCount . ".	$0", OutputVarCount , 1 )
		MyCount++
		MyCount := MyCount * OutputVarCount
	}
	Gosub, $SendBlock
	return

PreMenu_Renumber:
	Gosub, $GetBlock
	$CMDCall("PreMenu_ClearPrefix")
	$CMDCall("PreMenu_Number")
	return

PreMenu_1LineComment:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^.","; $0")
	Gosub, $SendBlock
	return

PreMenu_2LineComment:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^.","# $0")
	Gosub, $SendBlock
	return

PreMenu_3LineComment:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^.","// $0")
	Gosub, $SendBlock
	return

PreMenu_4LineComment:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^.","-- $0")
	Gosub, $SendBlock
	return

PreMenu_5LineComment:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^.",":: $0")
	Gosub, $SendBlock
	return

PreMenu_ClearPrefix:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^(; |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(# |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(// |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(-- |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(- |[0-9]+\.	|-	)","")
	Gosub, $SendBlock
	return

SortMenu_Ascending:
	Gosub, $GetBlock
	Sort, Block, C
	Gosub, $SendBlock
	return

SortMenu_Descending:
	Gosub, $GetBlock
	Sort, Block, CR
	Gosub, $SendBlock
	return

SortMenu_Integer:
	Gosub, $GetBlock
	Sort, Block, N
	Gosub, $SendBlock
	return

SortMenu_RemoveDups:
	Gosub, $GetBlock
	Sort, Block, U
	Gosub, $SendBlock
	return

TrimMenu_RTrim:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)[ \t]*$","")
	Gosub, $SendBlock
	return

TrimMenu_LTrim:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)^[ \t]*","")
	Gosub, $SendBlock
	return

TrimMenu_FullTrim:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)[ \t]*$","")
	Block := RegExReplace(Block,"m)^[ \t]*","")
	Gosub, $SendBlock
	return

TrimMenu_EmptyLines:
	Gosub, $GetBlock
	Block := RegExReplace(Block,"m)[ \t]*$","")
	Block := RegExReplace(Block,"m)^[ \t]*","")
	StringReplace, Block, Block, `r`n`r`n, `r`n, A
	Gosub, $SendBlock
	return

ProjectMenu_Run:
    IfNotExist, %MyFilePath%
	{
        return
	}
	; Save the file
	$CMDCall("FileMenu_Save")
	$ToolsCall(hEdit,"shelexec.exe",HE_GetFileName(hEdit))
	return

ProjectMenu_Makeit:
    IfNotExist, %MyFilePath%
	{
        return
	}
	$CMDCall("FileMenu_SaveAll")
	$ToolsCall(hEdit,"shelexec.exe",MyFilePath . "\MakeIt.bat")
	return

ProjectMenu_Jobs:
    IfNotExist, %MyFilePath%
    {
        return
	}
	$OpenFile(hEdit, MyFilePath .  "\Todo.txt")
	return

ProjectMenu_Folder:
    IfNotExist, %MyFilePath%
	{
        return
	}
    Run, shelexec.exe %MyFilePath%
	return

ProjectMenu_Backup:
    IfNotExist, %MyFilePath%
	{
        return
	}
	; Check or create backup path
	MyBackupPath := MyFilePath . "\zBackup\"
	IfNotExist, %MyBackupPath%
	{
		FileCreateDir, %MyBackupPath%
	}
	IfNotExist, %MyBackupPath%
	{
		msgbox, Failed to make backup directory
		return
	}

	; Make file name
	MyBackupFile := (Abs(A_HOUR)*60*60)+(Abs(A_MIN)*60)+(Abs(A_SEC))
	MyBackupFile := A_YYYY . "_" . A_MM . "_" . A_DD . "_" . MyBackupFile . "_" . MyFileName
	MyBackupFile := MyBackupPath . MyBackupFile

	; Copy the old file to backup - if it exists!
	fn = %MyFilePath%\%MyFileName%
	If (FileExist(fn)){
		FileCopy, %fn%, %MyBackupFile% ,1
	}

	; Save the current version
	$CMDCall("FileMenu_Save")

	return

FileMenu_ViewBackup:
ProjectMenu_Versions:
    IfNotExist, %MyFilePath%
	{
        return
	}
	MyBackupPath := MyFilePath . "\zBackup\"
    IfNotExist, %MyBackupPath%
	{
		msgbox, No backup directory
		return
	} Else {
        FileSelectFile, fn, 3,  %MyBackupPath%,  "Select a backup file ...", (*%MyFileName%)
        If Errorlevel
            return
        $OpenFile(hEdit, fn)
	}
	return

ToolsMenu_Shell:
	; Reset FileName as can be called called from button bar
	Gosub, $GetFilePath
    Run, %ComSpec% , %MyFilePath%
	return

ToolsMenu_Calculate:
	; ToDo ToolsMenu_Calculate
	return

ToolsMenu_Diff:
	IfNotExist, %MyFilePath%
	{
        return
	} Else {

	}
	$ToolsCall(hEdit,"TextDiff.exe",HE_GetFileName(hEdit))
	return

OptionsMenu_Font:
	if Dlg_Font(fFace, fStyle, pColor, true, $hwnd)
		HE_SetFont(hEdit, fStyle "," fFace)
	return

OptionsMenu_Tabs:
	InputBox, w, SetTabWidth ,Set Tab Width,,400,125,,,,,4
	if ErrorLevel
		return
	HE_SetTabWidth(hEdit, w)
	return

OptionsMenu_Colours:
	FileSelectFile, fn, 3, %A_ScriptDir%\hes, "Select a colour file ...", (*.hes)
    HE_SetColors(hEdit, colours) ; assign to the edit control
	return

OptionsMenu_SytaxColours:
	FileSelectFile, fn, 3, %A_ScriptDir%\hes, "Select a syntax highlight file ...", (*.hes)
	HE_SetKeywordFile(fn)
	return

OptionsMenu_FullScreen:
	WinMaximize, ahk_id %$hwnd%
	return

OptionsMenu_AutoIndent:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	HE_AutoIndent(hEdit, $AutoIndent := !$AutoIndent)
	return

OptionsMenu_LineNumbers:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	$LineNumbers := !$LineNumbers
	HE_LineNumbersBar(hEdit, $LineNumbers ? "automaxsize" : "hide")
	return

WindowsMenu_NextTab:
	MyTAB := HE_GetCurrentFile(hEdit)
	MyTAB++
	MaxTAB := HE_GetFileCount(hEdit)
	If (MyTAB < MaxTAB) {
		HE_SetCurrentFile(hEdit, MyTAB)
	} Else {
		HE_SetCurrentFile(hEdit, 0)
	}
	return

WindowsMenu_PrevTab:
	MyTAB := HE_GetCurrentFile(hEdit)
	MaxTAB := HE_GetFileCount(hEdit)
	If (MyTAB = 0 ) {
		HE_SetCurrentFile(hEdit, (MaxTAB-1))
	} Else {
		MyTAB := MyTAB-1
		HE_SetCurrentFile(hEdit, MyTAB)
	}
	return

WindowsMenu_FileList:
	MouseGetPos, x, y
	HE_ShowFileList(hEdit, x, y )
	return

HelpMenu_ToDo:
	$OpenFile(hEdit, A_ScriptDir . "\ToDo.txt")
	return

HelpMenu_Contents:
	$OpenFile(hEdit, A_ScriptDir . "\APEditor.md")
	return

HelpMenu_Keys:
    $OpenFile(hEdit, A_ScriptDir . "\APEditor.md")
	return

HelpMenu_About:
	msg := "A programmable editor`n`n"
		. "  HiEdit control is copyright of Antonis Kyprianou:`n"
		. "     http://www.winasm.net`n`n"
		. "  AHK wrapper by Majkinetor:`n"
		. "     https://github.com/majkinetor/mm-autohotkey`n`n"
		. "  Editor functionality by Gavin Holt"
	MsgBox, 48, About, %msg%
	return

WinDisable:
	; Get current window
	 Winget, WindowID
	 WinSet, ExStyle, -0x20, ahk_id %WindowID%
	 WinSet, Disable,, ahk_id %WindowID%
	 GuiControl,, ToggleDisable, Enable
	return

WinEnable:
	; Get current window
	 Winget, WindowID
	 WinSet, Enable,, ahk_id %WindowID%
	 WinSet, ExStyle, -0x20, ahk_id %WindowID%
	 GuiControl,, ToggleDisable, Disable
	 WinActivate,  ahk_id %WindowID%
	return

FontInc:
    fStyle := "s" . (SubStr(fStyle, 2) + 1)
    HE_SetFont(hEdit, fStyle "," fFace)
    return

FontDec:
    fStyle := "s" . (SubStr(fStyle, 2) - 1)
    HE_SetFont(hEdit, fStyle "," fFace)
    return

;# Script functions

$OpenFile(hEdit,fn) {
	HE_OpenFile(hEdit,fn)
	If (ErrorLevel=0) {
		MsgBox,48,"Error in $OpenFile","Unable to open the file"
		return
	} Else {
		$SetTitle(hEdit,$hwnd)
		ControlFocus, ahk_id %$hwnd%

        ; Check for previous edits
        Found := ""
        Loop, Read, %A_ScriptDir%\APEditor.his
        {
            If InStr(A_LoopReadLine, fn) {
                Found := A_LoopReadLine
            }
        }

        If not (Found = "") {
            ; Open at saved line
            StringSplit,Found,Found,@
            $GotoLine(hEdit,Found2)
        } Else {
            ; Record history
            FileAppend , %fn%@1`n , %A_ScriptDir%\APEditor.his
        }
    }
}

$GotoLine(hEdit, line) {
	line_idx := HE_LineIndex(hEdit, line-1)
	HE_SetSel(hEdit, line_idx, line_idx)
	HE_ScrollCaret(hEdit )
	return
}

$ReplaceLine(hEdit,line,text){
	line_idx := HE_LineIndex(hEdit, line)
	HE_SetSel( hEdit, line_idx, line_idx+HE_LineLength(hEdit, line_idx))
	HE_ReplaceSel(hEdit, text)
}

$IsRE(FindText){
	; Test if the FindText is a RE or not - can't be done as a regular find string may have dots
	If (RegExMatch(FindText, FindText))
		Return 0
	Else
		Return 1
}

$GetBlock:
	;Get start and end positions
	HE_GetSel(hEdit,BlockStart,BlockEnd)
	;Collect each line
	MySep =  `r`n
	BlockStartLindx := HE_LineFromChar(hEdit,BlockStart)
	BlockEndLindx:= HE_LineFromChar(hEdit,BlockEnd)
	BlockCounter := BlockStartLindx
	;First Line
	Block := HE_GetLine(hEdit,BlockCounter)
	BlockCounter++
	; Loop through the rest -
	; ToDo $GetBlock - this fails on the last line of the file!
	While (BlockCounter<= BlockEndLindx ) {
		Block := Block MySep HE_GetLine(hEdit,BlockCounter)
		BlockCounter++
	}
	; Add terminal EOL
	;Block := Block MySep

	; Set Selection - for later replacement
 	HE_SetSel(hEdit,HE_LineIndex(hEdit, BlockStartLindx) , HE_LineIndex(hEdit, BlockEndLindx) + HE_LineLength(hEdit,BlockEndLindx))

	; Set cursor for Select line up

	return

$SendBlock:
	; Send the text
	HE_ReplaceSel(hEdit, Block)
	; Reselect the new block - may be a different length to the old block!
	HE_SetSel(hEdit,HE_GetSel(hEdit)-StrLen(Block),HE_GetSel(hEdit))
	return

$GetAllText(hEdit){
	$CMDCall("SelectMenu_All")
	Return HE_GetSelText(hEdit)
}

$SendText(hEdit,Text){
	; First option - via the keyboard hook - slow and adds extra CTLF
	; SendInput, {raw} %Text%
	; Second option - message to hiEdit control directly
	SendMessage,0xC2,,&Text,,ahk_id %hEdit%
}

$GetRelPath(CurrentFn,InsertFn){
	If (FileExist(CurrentFn)){
		Loop, %CurrentFn%
		{
			CurrentP := A_LoopFileDir
			Loop, %InsertFn%
			{
				InsertP := A_LoopFileDir
				If (CurrentP = InsertP){
					; Same directory
					ReplaceText = %A_LoopFileName%
					break
				}

				If (substr(CurrentP,1,1)<>substr(InsertP,1,1) ){
					msgbox, Can't make relative path to different drive!
					ReplaceText := InsertFn
					break
				}

				IfInstring, CurrentP , %InsertP%
				{
					; Insert above edit file
					StringReplace, ReplaceText, CurrentP, %InsertP%
					ReplaceText := SubStr(ReplaceText, 2)
					ReplaceText := RegExReplace(ReplaceText,"\w+" ,"..")
					ReplaceText := ReplaceText "\" A_LoopFileName
					break
				}

				IfInstring, InsertP , %CurrentP%
				{
					; Insert below edit file
					StringReplace, ReplaceText, InsertP,  %CurrentP%
					ReplaceText := substr(ReplaceText,2) "\" A_LoopFileName
					break
				}

				;Else

				Counter := strlen(CurrentP)
				Loop %Counter% {
					If (substr(CurrentP,A_Index,1) = substr(InsertP,A_Index,1)) {
						;
					} Else {
						; Remove common path
						ReplaceText := substr(InsertP,A_Index)
 						; Add up levels
						ReplaceText := RegExReplace(substr(CurrentP,A_Index),"\w+" ,"..")   "\" ReplaceText
						; Add FileName
						ReplaceText := ReplaceText "\" A_LoopFileName
						break
					}
				}
			}
		}
	} Else {
		msgbox, Can't make relative path to unnamed file!
		ReplaceText := InsertFn
	}
	Return %ReplaceText%
}

$ToolsCall(hEdit,fnTool,param){
	; ToDo $ToolsCall - this fails if param file name has spaces!
	Run, %fnTool% %A_Space% "%param%",""
}

$ComspecCall(hEdit,fnTool,param,output,MyFilePath){
	IfExist, %fnTool%
	{
		Runwait, %ComSpec% /c %fnTool% %A_Space%  %param% > %output% , %MyFilePath% , Hide
	}
}

;# Callback Functions
; ToDo OnHiEdit - how to use?
OnHiEdit(Hwnd, Event, Info)
{
	OutputDebug % Hwnd " | " Event  " | " Info
}

;# GuiEvents see also OnMessage in help
; I tried to move this section and it wouldn't compile
GuiContextMenu:
    return

GuiSize:
    return

GuiEscape:
	;$CMDCall("FileMenu_Close")
	; Disabled to allow esc from message boxes
	return

GuiClose:
OnExit:
	$CMDCall("FileMenu_Exit")
	ExitApp
	return

GuiDropFiles:
	Loop, parse, A_GuiEvent, `n
	{
		fn=%A_LoopField%
		; Check its not already open
		N:=HE_GetFileCount(hEdit)
		Loop,%N% ; Faire le tour des onglets
		{
			idx:=A_Index-1     ; Commencer � 0
			nf:=HE_GetFileName(hEdit,idx)
			; If it's already open
			IfInString,nf,%fn%
			{
				HE_SetCurrentFile(hEdit,idx)
				Break
			}
			; If it's not in the list
			If (N=A_Index)
			{
				$OpenFile(hEdit,fn)
				Break
			}
		}
	}
    Return

;# Includes
; Library files
#include inc\Attach.ahk
#include inc\COM.ahk
#include inc\Dlg.ahk
#include inc\HIEdit.ahk

; Print by Jballi
#include inc\HiEdit_Print.ahk

; Plugins - can't load dynamically and are compiled into the exe.
#include plg\TabExpand.ahk
#include plg\Autocorrect.ahk
#include plg\Grammar.ahk
#include plg\DyslexicTypos.ahk
