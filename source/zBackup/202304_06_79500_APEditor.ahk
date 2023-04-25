;==================A Programmable Editor Gavin M Holt ===========
; Standing upon the shoulders of giants, developed borrowing from various scripts:
;	HiEdit.ahk		Antonis Kyprianou
;	HiEdit _test.ahk 	Magnetometer
;	AHKPAd			Michael Peters
;	Vic	Editor		Normand Lamoureux
;
; I have tried to avoid operations that load the whole file - preferring to process a line at a time,
; exceptions include:
;	Block:			If you "select all" the whole file is in memory
; 	FileMenu_OpenTemplate:	Read whole file in then inserts
; 	EditMenu_FindREDown:	Reads the rest of the file before each search
; 	InsertMenu_File:	Reads whole file in then inserts
;
; You may set #MaxMem to increase the maximum variable size from the default of 64MB
;
;==================Setup AHK Environment ========================
#NoEnv
#SingleInstance Force
#NoTrayIcon
#MaxMem 128
SetWorkingDir, %A_ScriptDir%
AutoTrim,Off
SetBatchLines,-1
SetControlDelay,-1
SetWinDelay,-1
ListLines Off
DetectHiddenWindows, On
SetTitleMatchMode,2
SendMode, Input
Process,Priority,,A
CoordMode, Mouse, Relative

;==================GUI SETUP ================================
; Set up the GUI object
; Menu, TRAY, Icon, img/APEditor.png
Gui, +LastFound +Resize
hwnd := WinExist()
Gui, font, s12, Consolas   ; This does not seem to work with the menu fonts

;==================Toolbar ==================================
; Static pictures, no tooltips for speed!
; WS_CLIPSIBLINGS = "0x4000000"
; Gui, Add, Picture, %WS_CLIPSIBLINGS%  HWNDToolBack x0 y0 w965 h44 BackgroundTrans,img/bluegrad.bmp
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

;==================Menus ================================
; Before display for speed?
My_MenuCreate()

; Default menu settings - perhaps an ini file in the future
Menu, FileMenu, Check, &Monitor
Menu, OptionsMenu, Check, &Line Numbers
Menu, OptionsMenu, Check, &Auto Indent
Menu, OptionsMenu, Check, &Highlighting

;==================HiEdit ================================
hEdit := HE_Add(hwnd,0,44,965,636, "HSCROLL VSCROLL HILIGHT TABBEDBOTTOM FILECHANGEALERT")
; hEdit := HE_Add(hwnd,0,0,965,680, "HSCROLL VSCROLL HILIGHT TABBEDBOTTOM FILECHANGEALERT")
fStyle := "s18" ,fFace  := "Consolas"
HE_SetFont( hEdit, fStyle "," fFace)
HE_SetTabWidth(hEdit, 4)
; #include hes/DarkColours.hes ; make the colour matrix
#include hes/LightColours.hes ; make the colour
HE_SetColors(hEdit, colours) ; assign to the edit control
HE_SetKeywordFile( "APEditor.hes")
HE_AutoIndent(hedit, true), autoIndent := true
HE_LineNumbersBar(hEdit, "automaxsize"), lineNumbers := true

;==================Statusbar =============================
; Do I want one?

;==================Show the GUI ==========================
Attach(hEdit, "w h")
Attach(ToolBack, "w")
Gui, Show, w965 h680, APEditor
Gui, Maximize
SetTimer, My_SetTitle, 50

;==================Load files from command line or Drag'n'Drop ==============
; Handle files from command line
; ToDo Do we need a loop to cope with multiple input files
Input = %1%
If Input
{
	My_OpenFile(hEdit, Input)
}

;==================End of Autoexec Section ===========================
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
				My_OpenFile(hEdit,fn)
				Break
			}
		}
	}
Return

;==================Hotkeys ===========================
SetTitleMatchMode, 2

#IfWinActive ahk_class AutoHotkeyGUI

	^A::	My_CMDCall("SelectMenu_All")
	^B::	Send {Home}
;	^C::	COPY!!!!
	^D::	My_CMDCall("BlockMenu_Duplicate")
	^E::	Send {End}
	^F::	My_CMDCall("EditMenu_Find")
	^G::	My_CMDCall("EditMenu_GoTo")
	^H::	My_CMDCall("EditMenu_Replace")
; 	^I::	My_CMDCall("BlockMenu_Indent")
	^I::	My_CMDCall("InsertMenu_Insertor")
	^J::	My_CMDCall("")
	^K::	My_CMDCall("EditMenu_DelEOL")
	^L::	My_CMDCall("SelectMenu_LineDown")
	^M::	My_CMDCall("EditMenu_Mark")
	^N::	My_CMDCall("FileMenu_New")
	^O::	My_CMDCall("FileMenu_OpenShortCut")
	^P::	My_CMDCall("FileMenu_Print")
	^Q::	My_CMDCall("BlockMenu_Comment")
	^R::	My_CMDCall("FileMenu_Revert")
	^S::	My_CMDCall("FileMenu_Save")
	^T::	My_CMDCall("")
	^U::	My_CMDCall("EditMenu_UnMark")
;	^V::	PASTE
	^W::	My_CMDCall("FileMenu_Close")
;	^X::	CUT
	^Y::	My_CMDCall("BlockMenu_Yank")
;	^Z::	UNDO

;	^+A::	All occurances for multi cursor editor
	^+B::	Send +{Home}
	^+C::	My_CMDCall("EditMenu_CopyAppend")
	^+D::	My_CMDCall("") ; Window Peek Down
	^+E::	Send +{End}
    ^+F::	My_CMDCall("EditMenu_FindRE")
	^+G::	My_CMDCall("") ; FilterGoto
	^+H::	My_CMDCall("EditMenu_ReplaceAll")
	^+I::	My_CMDCall("SelectMenu_Brace")
	^+J::	My_CMDCall("")
	^+K::	My_CMDCall("EditMenu_DelBOL")
	^+L::	My_CMDCall("SelectMenu_LineUp")
	^+N::	My_CMDCall("")
	^+M::	My_CMDCall("")
;	^+O::   My_CMDCall("")
	^+P::	My_CMDCall("")
;	^+Q::   My_CMDCall("")
	^+R::	My_CMDCall("")
	^+S::	My_CMDCall("FileMenu_SaveAs")
	^+T::	My_CMDCall("")
	^+U::	My_CMDCall("")
	^+V::	My_CMDCall("EditMenu_PasteText")
	^+W::	My_CMDCall("")
	^+X::	My_CMDCall("EditMenu_CutAppend")
;	^+Y::   My_CMDCall("")
;	^+Z::	UNDO

	^!A::	My_CMDCall("")
	^!B::	My_CMDCall("ProjectMenu_Backup")
	^!C::	My_CMDCall("")
	^!D::	My_CMDCall("")
	^!E::	My_CMDCall("")
	^!F:: 	My_CMDCall("")
	^!G::	My_CMDCall("")
	^!H::	My_CMDCall("EditMenu_Replaceinfiles")
	^!I::	My_CMDCall("InsertMenu_File")
	^!J::	My_CMDCall("ProjectMenu_Jobs")
	^!K::	My_CMDCall("")
	^!L::	My_CMDCall("")
	^!M::	My_CMDCall("ProjectMenu_MakeIt")
;	^!N::	My_CMDCall("")
	^!O::	My_CMDCall("")
;	^!P::	My_CMDCall("")
;	^!Q::	My_CMDCall("")
	^!R::	My_CMDCall("ProjectMenu_Run")
	^!S::	My_CMDCall("")
	^!T::	My_CMDCall("FileMenu_OpenTemplate")
	^!U::	My_CMDCall("")
;	^!V::	My_CMDCall("")
	^!W::	My_CMDCall("")
	^!X::	My_CMDCall("")
;	^!Y::   My_CMDCall("")
;	^!Z::   My_CMDCall("")

    !W::	    My_CMDCall("WindowsMenu_FileList")
    !SC02B::	My_CMDCall("ProjectMenu_Folder")

	^Space::	My_CMDCall("SelectMenu_Word")
    ^!SC02B::	My_CMDCall("ToolsMenu_Shell")

	^SC027::	My_CMDCall("PreMenu_1LineComment") ; ^;
	^SC02B::	My_CMDCall("PreMenu_2LineComment") ; ^#
	^/::		My_CMDCall("PreMenu_3LineComment") ; ^/
	^-::		My_CMDCall("PreMenu_4LineComment") ; ^-
	^;::		My_CMDCall("PreMenu_5LineComment") ; ^;
	^=::		My_CMDCall("PreMenu_ClearPrefix")

	^F1::	My_CMDCall("")
	F5::	My_CMDCall("FileMenu_Revert")
	F9::	My_CMDCall("EditMenu_Find")
	F10::	My_CMDCall("EditMenu_FindRE")
	F11::	My_CMDCall("EditMenu_Replace")


	!Enter::	Send {Asc 010}    ; Alt+Enter
	+Enter::	SendInput <br>
	; ^Enter::	Seems to add line below

;	^Right::	Word Right
;	^Left::		Word Left

	^TAB::	My_CMDCall("WindowsMenu_NextTab")
	^+TAB::	My_CMDCall("WindowsMenu_PrevTab")

;	Up::		Up
;	Down::		Down

	+Up::		My_CMDCall("SelectMenu_LineUp")
	+Down::	    My_CMDCall("SelectMenu_LineDown")

	^Up::		My_CMDCall("EditMenu_FindUp")
	^Down::		My_CMDCall("EditMenu_FindDown")

	^+Up::		My_CMDCall("BlockMenu_ShiftUp")
	^+Down::	My_CMDCall("BlockMenu_ShiftDown")

	!Left::		My_CMDCall("EditMenu_GoBack")
	!Right::	My_CMDCall("EditMenu_GoForward")

;	+!Up::      My_CMDCall("")
;	+!Down::    My_CMDCall("")

;	^DEL::		; 	Delete top next word
;	+DEL::		; 	BACKSPACE if not selection, ^X if there is a selection
;	^+DEL::	; 	Delete block

    ^WheelUp::   My_CMDCall("My_FontInc")
    ^WheelDown:: My_CMDCall("My_FontDec")

#IfWinActive

;==================HiEdit Naviagtion Keys=======================
; 	+{Right} 	Extend a selection one character to the right. SHIFT+RIGHT ARROW
; 	+{Left} 	Extend a selection one character to the left. SHIFT+LEFT ARROW
; 	+^{Right}	Extend a selection to the end of a word. CTRL+SHIFT+RIGHT ARROW NB To the next word including W
; 	+^{Left}	Extend a selection to the beginning of a word. CTRL+SHIFT+LEFT ARROW
; 	+{End}		Extend a selection to the end of a line. SHIFT+END
; 	+{Home}	    Extend a selection to the beginning of a line. SHIFT+HOME
; 	Over written see above	Extend a selection one line down. SHIFT+DOWN ARROW
; 	Over written see above	Extend a selection one line up. SHIFT+UP ARROW
; 	+{PgDn}	    Extend a selection one screen down. SHIFT+PAGE DOWN
; 	+{PgUp}	    Extend a selection one screen up. SHIFT+PAGE UP
; 	+^{Home}	Extend a selection to the beginning of a document. CTRL+SHIFT+HOME
; 	+^{End}	    Extend a selection to the end of a document. CTRL+SHIFT+END
; 	^A			Extend a selection to include the entire document. CTRL+A

;==================Windows Global Keys=======================
; Avoid global windows keys

;==================Menu Definitons===========================
My_MenuCreate(){

	Menu, FileMenu, Add, &New	Ctrl+N,MenuHandler
	Menu, FileMenu, Add, &Open...	Ctrl+O,	MenuHandler
	Menu, FileMenu, Add, Rever&t	Ctrl+R,MenuHandler
	Menu, FileMenu, Add, &Close	Ctrl+W,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, Open Se&lection...	Ctrl+Shift+O,	MenuHandler
	Menu, FileMenu, Add, Open &Template...	Ctrl+Alt+T,MenuHandler
;	Menu, FileMenu, Add, Open &History...	Ctrl+H,		MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Save	Ctrl+S,		MenuHandler
	Menu, FileMenu, Add, Save &As...	Ctrl+Shift+S,MenuHandler
 	Menu, FileMenu, Add, Save A&ll,	MenuHandler
	Menu, FileMenu, Add, Save &Backup...	Ctrl+Alt+B,MenuHandler
; 	Menu, FileMenu, Add, Save S&election...,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Monitor,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, Print...	Ctrl+P,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, E&xit,	MenuHandler

	; Submenus for Edit, must be defined first!
; 	Menu, InsertMenu, Add, &Insertor...	Alt+I,MenuHandler
; 	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, &Date,MenuHandler
	Menu, InsertMenu, Add, &Time,MenuHandler
	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, &File...	Ctrl+Alt+I,MenuHandler
	Menu, InsertMenu, Add, File &Name	Ctrl+Alt+N,MenuHandler
	Menu, InsertMenu, Add, &Get FileName..	Ctrl+Alt+G,MenuHandler
	Menu, InsertMenu, Add, Get &Rel FileName..	Ctrl+Alt+K,MenuHandler

    Menu, SelectMenu, Add, &Word	Ctrl+Space,MenuHandler
	Menu, SelectMenu, Add, &Brace	Ctrl+Shift+J,MenuHandler
	Menu, SelectMenu, Add, Line&Down	Ctrl+L,MenuHandler
	Menu, SelectMenu, Add, Line&Up	Ctrl+Shift+L,MenuHandler
	Menu, SelectMenu, Add, &All	Ctrl+A,MenuHandler

	Menu, FormatMenu, Add, &Upper Case,MenuHandler
	Menu, FormatMenu, Add, &Lower Case,MenuHandler
	Menu, FormatMenu, Add, &Reverse Case,MenuHandler
	Menu, FormatMenu, Add, &Proper Case,MenuHandler

	Menu, EOLMenu,Add, Win CRLF,MenuHandler
	Menu, EOLMenu,Add, Unix LF,MenuHandler
	Menu, EOLMenu,Add, Mac CR,MenuHandler

	Menu, EditMenu, Add, &Undo	Ctrl+Z,MenuHandler
	Menu, EditMenu, Add, R&edo	Ctrl+Y,MenuHandler
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
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Select,		:SelectMenu
	Menu, EditMenu, Add, &Insert,		:InsertMenu
	Menu, EditMenu, Add, C&hange Case,	:FormatMenu
	Menu, EditMenu, Add, Convert &EOL,	:EOLMenu

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
	Menu, PreMenu, Add,  &Clear Prefix	,MenuHandler

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

	Menu, ProjectMenu, Add, &Run	Ctrl+Alt+R,MenuHandler
	Menu, ProjectMenu, Add, &Makeit 	Ctrl+Alt+M,MenuHandler
	Menu, ProjectMenu, Add, &Jobs	Ctrl+Alt+J,MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, &Folder	Alt+#,MenuHandler
	Menu, ProjectMenu, Add, &Backup	Ctrl+Alt+B,MenuHandler
	Menu, ProjectMenu, Add, &Versions	Ctrl+Alt+V,MenuHandler

	Menu, MacrosMenu, Add, &Dir,MenuHandler
	Menu, MacrosMenu, Add, &Edit,MenuHandler
	Menu, MacrosMenu, Add, &Config,MenuHandler
	Menu, MacrosMenu, Add
	Menu, MacrosMenu, Add, &Record	Ctrl+F7,MenuHandler
	Menu, MacrosMenu, Add, &Play	Ctrl+F8,MenuHandler
	Menu, MacrosMenu, Add
	Menu, MacrosMenu, Add, &Load,MenuHandler
	Menu, MacrosMenu, Add, &Save,MenuHandler
	Menu, MacrosMenu, Add, &Append,MenuHandler

    ; Submenus for Options, must be defined first!

	Menu, OptionsMenu, Add, &Font,MenuHandler
	Menu, OptionsMenu, Add, &Tabs,MenuHandler
	Menu, OptionsMenu, Add, &Colours,MenuHandler
	Menu, OptionsMenu, Add, Syta&x Colours,MenuHandler
	Menu, OptionsMenu, Add
	Menu, OptionsMenu, Add, &Auto Indent,MenuHandler
	Menu, OptionsMenu, Add, &Line Numbers,MenuHandler
	Menu, OptionsMenu, Add, &Highlighting,MenuHandler
	Menu, OptionsMenu, Add
	Menu, OptionsMenu, Add, Tool&bar,MenuHandler
	Menu, OptionsMenu, Add, &Statusbar,MenuHandler
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
	Menu, MyMenuBar, Add,&Project,		:ProjectMenu
	Menu, MyMenuBar, Add,&Options,		:OptionsMenu
	Menu, MyMenuBar, Add,&Windows,	    :WindowsMenu
	Menu, MyMenuBar, Add,&Help,		    :HelpMenu
	Menu, MyMenuBar, Color,  FFFFFFFF
	Gui, Menu, MyMenuBar
}

; Menu Handler and supporting functions
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
	Gosub, My_GetFilePath
	Gosub, %MenuLabel%
	return

My_CMDCall(CMD) {
	;Some commands can't call gosub, they need to call a function!
	Gosub, My_GetFilePath ; Not sure if these variables are set as global
	Gosub, %CMD%
}

My_GetFilePath:
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

;==================Command Scripts - return delimited===========================

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
		My_OpenFile(hEdit, Sel)
	} Else {
		Sel := MyFilePath . "\" . Sel
		If (FileExist(Sel) and InStr(FileExist(Sel), "D")=0 ){
			My_OpenFile(hEdit, Sel)
		} Else {
		My_CMDCall("FileMenu_Open")
		}
	}
	return

FileMenu_Open:
	FileSelectFile, fn, 3, %MyFilePath% , Open a file
	if Errorlevel
		return
	My_OpenFile(hEdit, fn)
	return

FileMenu_OpenTemplate:
	FileSelectFile, fn, 3, %A_ScriptDir%\tem\, Open a template: General,
	If Errorlevel {
		FileSelectFile, fn, 3, %MyFilePath%\_Template\, Open a template: Local,
		If Errorlevel {
			return
		}
	}

	HE_NewFile(hEdit)
	FileRead, iText, %fn%
	My_SendText(hEdit,iText)
	return

FileMenu_Save:
	If FileExist(HE_GetFileName(hEdit)){
		HE_SaveFile(hEdit, HE_GetFileName(hEdit))
		HE_SetModify(hEdit, 0)
		My_SetTitle(hEdit,hwnd)
	} Else {
		My_CMDCall("FileMenu_SaveAs")
	}
	return

FileMenu_SaveAs:
	FileSelectFile, fn, S 16, %MyFilePath% , Save File As..
	if (Errorlevel)
		return
	HE_SaveFile(hEdit, fn, -1)
	HE_SetModify(hEdit, 0)
	My_SetTitle(hEdit,hwnd)
	return

FileMenu_SaveAll:
	nFiles := HE_GetFileCount(hEdit)
	Loop,%nFiles%
	{
		My_CMDCall("FileMenu_Save")
		My_CMDCall("WindowsMenu_NextTab")
	}
	Gosub, My_GetFilePath ; Get back the correct file / path
	return

FileMenu_SaveSelection:
	HE_Copy(hEdit)
	HE_NewFile(hEdit)
	HE_Paste(hEdit)
	My_CMDCall("FileMenu_SaveAs")
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
		My_FileName :=  HE_GetFileName(hEdit)
		msgbox,  3, APEditor - File not saved , Save changes to %My_FileName% ?
		IfMsgBox, Yes
 			My_CMDCall("FileMenu_Save")
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
		My_CMDCall("FileMenu_Close")
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

EditMenu_PasteText:
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

EditMenu_Mark:
    MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit)) + 1
    If (LocStack%Pointer% != MyLineNumber)
    {
        Pointer++
        LocStack%Pointer% := MyLineNumber
    }
	return

EditMenu_UnMark:
    ; Todo EditMenu_UnMark
    return

EditMenu_Goto:
	Sel:= HE_GetSelText(hEdit)
	cnt := HE_GetLineCount(hEdit)
	; Ask for line number - modal dialog
	Gui, +OwnDialogs
	InputBox, line, Go To Line, Enter line number or function name, , 400, 120, , , , ,%Sel%
	If ErrorLevel
		return

	If line is integer
	{
		If (line > cnt) {
			line := cnt
		}
		My_GotoLine(hEdit, line)
		return
	}

	If line is not integer
	{
		FindText := line
		MyLastFind := "RE"
		GoSub, EditMenu_FindDown
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
        My_GotoLine(hEdit, LocStack%Pointer%)
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
    My_GotoLine(hEdit, LocStack%Pointer%)
    return

EditMenu_Find:
	; Gosub, My_GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel := HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel := ""
	}

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, FindText, Find , Enter search text, , 400, 120, , , , ,%Sel%
	if ErrorLevel
		return

	; Default to looking downwards
	; I really don't like creating a state ... but
	MyLastFind := "Text"
	GoSub, EditMenu_FindDown
	return

EditMenu_FindRE:
	; Gosub, My_GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	}

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, FindText, Find, Enter regular expression, , 400, 120, , , , ,%Sel%
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
	; Gosub, My_GetFilePath ; If called from the toolbar we will miss these instructions

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
	InputBox, ReplaceCMD, Replace, <find_str>|<replace_str>, , 400, 120, , , , ,%ReplaceCMD%
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
	; Gosub, My_GetFilePath ; If called from the toolbar we will miss these instructions

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
	InputBox, ReplaceCMD, Replace All, <find_str>|<replace_str>, , 400, 120, , , , ,%ReplaceCMD%
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

	My_CMDCall("FileMenu_Save")
	Gosub, My_WinDisable
	Runwait, grepwin.exe /portable /searchpath:"%MyFilePath%" /filemask:"%MyFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
	Gosub, My_WinEnable
	Gosub, FileMenu_Revert
	return

SelectMenu_Word:
	MouseMove, %A_CaretX%, %A_CaretY%
	Send, {LButton}{LButton}
	return

SelectMenu_Brace:
    ; ToDo SelectMenu_Brace
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
	My_Index := 1
	While (My_Index < HE_GetLineCount(hEdit) ){
		Text 		:= HE_GetLine(hEdit, My_Index-1)
		FirstChar 	:= HE_LineIndex(hEdit, My_Index-1)
		LastChar 	:= FirstChar + HE_LineLength(hEdit, My_Index-1)

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
			msgbox, %My_Index%   -  this is an EOF break
		}
		Else
		{
			; Unknown EOL - we should not get here
			msgbox, % My_Index   "-  this is an  unknown EOL code: " Asc(SubStr(NextChar, 1 , 1) ) A_Space Asc(SubStr(NextChar, 2 , 1) )
		}

		; Increment counter
		My_Index++
	}
    ; Restore position
	HE_SetSel(hEdit,CurrChar,CurrChar)
	HE_ScrollCaret(hEdit)
	return

InsertMenu_Insertor:

    return

InsertMenu_File:
	FileSelectFile, ifn, 3, %MyFilePath%, Insert file contents
	FileRead, iText, %ifn%
	My_SendText(hEdit,iText)
	return

InsertMenu_Date:
	FormatTime,date,YYYYMMDDHH24MISS,dd-MM-yyyy
	My_SendText(hEdit,date)
	return

InsertMenu_Time:
	FormatTime,time,YYYYMMDDHH24MISS,HH':'mm
	My_SendText(hEdit,time)
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
	ifn := My_GetRelPath(HE_GetFileName(hEdit,-1),ifn)
	Sendinput, % ifn
	return

BlockMenu_Indent:
	Send {Tab}
	Gosub, My_GetBlock
	return

BlockMenu_Outdent:
	Gosub, My_GetBlock
	Send +{Tab}
	return

BlockMenu_Duplicate:
	Gosub, My_GetBlock
	Send {Down}{Home}{Enter}{Up}
	Gosub, My_SendBlock
	return

BlockMenu_Yank:
	Gosub, My_GetBlock
	Send {Del}
	Send {Del}
	Return

BlockMenu_Join:
	Gosub, My_GetBlock
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
	Gosub, My_SendBlock
	return

BlockMenu_ShiftUp:
	Gosub, My_GetBlock
	SendInput {Del}{Del}{Up}{Enter}{Up}
	Gosub, My_SendBlock
	return

BlockMenu_ShiftDown:
	Gosub, My_GetBlock
	SendInput {Del}{Del}{Down}{Enter}{Up}
	Gosub, My_SendBlock
	return

BlockMenu_Comment:
	Gosub, My_GetBlock
	Block := "/*" . A_Tab . Block . A_Tab . "*/"
	Gosub, My_SendBlock
    return

BlockMenu_BlockComment:
	Gosub, My_GetBlock
    ; Thi sneeds to know prefix by filetype
    Block := RegExReplace(Block,"m)^.","; $0")
	Gosub, My_SendBlock
	return

BlockMenu_Winsorter:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Winsorter\WinSorter.exe","")
	return

PreMenu_Bullet:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^.","-	$0")
	Gosub, My_SendBlock
	return

PreMenu_Number:
	Gosub, My_GetBlock
	MyCount = 1
	While (MyCount > 0){
		Block := RegExReplace(Block,"m)^[a-zA-Z]", MyCount . ".	$0", OutputVarCount , 1 )
		MyCount++
		MyCount := MyCount * OutputVarCount
	}
	Gosub, My_SendBlock
	return

PreMenu_Renumber:
	Gosub, My_GetBlock
	My_CMDCall("PreMenu_ClearPrefix")
	My_CMDCall("PreMenu_Number")
	return

PreMenu_1LineComment:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^.","; $0")
	Gosub, My_SendBlock
	return

PreMenu_2LineComment:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^.","# $0")
	Gosub, My_SendBlock
	return

PreMenu_3LineComment:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^.","// $0")
	Gosub, My_SendBlock
	return

PreMenu_4LineComment:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^.","-- $0")
	Gosub, My_SendBlock
	return

PreMenu_5LineComment:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^.",":: $0")
	Gosub, My_SendBlock
	return

PreMenu_ClearPrefix:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^(; |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(# |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(// |[0-9]+\.	|-	)","")
	Block := RegExReplace(Block,"m)^(-- |[0-9]+\.	|-	)","")
	Gosub, My_SendBlock
	return

SortMenu_Ascending:
	Gosub, My_GetBlock
	Sort, Block, C
	Gosub, My_SendBlock
	return

SortMenu_Descending:
	Gosub, My_GetBlock
	Sort, Block, CR
	Gosub, My_SendBlock
	return

SortMenu_Integer:
	Gosub, My_GetBlock
	Sort, Block, N
	Gosub, My_SendBlock
	return

SortMenu_RemoveDups:
	Gosub, My_GetBlock
	Sort, Block, U
	Gosub, My_SendBlock
	return

TrimMenu_RTrim:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)[ \t]*$","")
	Gosub, My_SendBlock
	return

TrimMenu_LTrim:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)^[ \t]*","")
	Gosub, My_SendBlock
	return

TrimMenu_FullTrim:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)[ \t]*$","")
	Block := RegExReplace(Block,"m)^[ \t]*","")
	Gosub, My_SendBlock
	return

TrimMenu_EmptyLines:
	Gosub, My_GetBlock
	Block := RegExReplace(Block,"m)[ \t]*$","")
	Block := RegExReplace(Block,"m)^[ \t]*","")
	StringReplace, Block, Block, `r`n`r`n, `r`n, A
	Gosub, My_SendBlock
	return

MacrosMenu_Dir:
	;My_ToolsCall(hEdit,"shelexec.exe", A_ScriptDir . "\mac\")
	Run, explorer.exe /e`,/root`,	%A_ScriptDir%\mac\
	return

MacrosMenu_Edit:
	FileSelectFile, fn, 3, %A_ScriptDir%\mac\ , Open a file
	if Errorlevel
		return
	My_OpenFile(hEdit, fn)
	return

MacrosMenu_Config:
	My_OpenFile(hEdit, A_ScriptDir . "\mac\default.ahk")
	return

MacrosMenu_Record:
	My_ToolsCall(hEdit,"Macro.exe","")
	Sleep, 500
	SendInput ^{F7}
	return

MacrosMenu_Play:
	SendInput ^{F8}
	return

MacrosMenu_Load:
	FileSelectFile, fn, 3, %A_ScriptDir%\mac\ , Load a macro
	if Errorlevel
		return
	My_ToolsCall(hEdit,"Macro.exe",fn)
	return

MacrosMenu_Save:
	FileSelectFile, fn, S 16, %A_ScriptDir%\mac , Save Macro As.., *.mac
	if (Errorlevel) {
		return
	}
	FileCopy, %A_ScriptDir%\plg\Macro.ini, %fn%
	My_ToolsCall(hEdit,"Macro.exe",fn)
	return

MacrosMenu_Append:
	FileSelectFile, fn, S 1, %A_ScriptDir%\..\mac , Save Macro As.., *.mac
	if (Errorlevel)
		return
	IniRead,macro,%A_ScriptDir%\Macro.ini,Settings,macro
	FileAppend, %macro%, %fn%
	Sleep, 50
	My_ToolsCall(hEdit,"Macro.exe",fn)
	return

ProjectMenu_Folder:
    IfNotExist, %MyFilePath%
	{
        return
	}
    Run, shelexec.exe %MyFilePath%
	return

ProjectMenu_Run:
    IfNotExist, %MyFilePath%
	{
        return
	}
	; Save the file
	My_CMDCall("FileMenu_Save")
    My_ToolsCall(hEdit,"shelexec.exe",HE_GetFileName(hEdit))
	return

ProjectMenu_Makeit:
    IfNotExist, %MyFilePath%
	{
        return
	}
	My_CMDCall("FileMenu_SaveAll")
	My_ToolsCall(hEdit,"shelexec.exe",MyFilePath . "\MakeIt.bat")
	return

ProjectMenu_Jobs:
    IfNotExist, %MyFilePath%
    {
        return
	}
	My_OpenFile(hEdit, MyFilePath .  "\Todo.txt")
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
	My_CMDCall("FileMenu_Save")

	return

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
        My_OpenFile(hEdit, fn)
	}
	return

OptionsMenu_Font:
	if Dlg_Font(fFace, fStyle, pColor, true, hwnd)
		HE_SetFont(hEdit, fStyle "," fFace)
	return

OptionsMenu_Tabs:
	InputBox, w, SetTabWidth ,Set Tab Width,,150,120,,,,,4
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
	WinMaximize, ahk_id %hwnd%
	return

OptionsMenu_Autoindent:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	HE_AutoIndent(hEdit, autoIndent := !autoIndent)
	return

OptionsMenu_LineNumbers:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	lineNumbers := !lineNumbers
	HE_LineNumbersBar(hEdit, lineNumbers ? "automaxsize" : "hide")
	return

OptionsMenu_Highlighting:
	; ToDo OptionsMenu_Highlighting
	return

OptionsMenu_Toolbar:
	; ToDo OptionsMenu_Toolbar
	return

OptionsMenu_Statusbar:
	; ToDo OptionsMenu_Statusbar
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
	My_OpenFile(hEdit, A_ScriptDir . "\APEditor.txt")
	return

HelpMenu_Contents:
	; ToDo HelpMenu_Contents
	return

HelpMenu_Keys:
    ; ToDo HelpMenu_Keys
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

ToolsMenu_Shell:
	; Reset FileName as can be called called from button bar
	Gosub, My_GetFilePath
    Run, cmd.exe, %MyFilePath%
	return

;==================Timers - here so I remember them!=========================

My_SetTitle: ; SetTimer won't call a function!
	My_SetTitle(hEdit,hwnd)
	return

My_SetTitle(hEdit,hwnd){
	if HE_GetModify(hEdit, idx=-1) {
		pre = *
		}
	fn:=HE_GetFileName(hEdit,-1)
	WinSetTitle,ahk_id %hwnd%,,%pre%%fn% - APEditor
	return
}

;==================Supporting Functions=========================

My_Control(ClassNN) {
    MouseGetPos,,,,control
    return (ClassNN = control)
}

My_OpenFile(hEdit,fn){
	HE_OpenFile(hEdit,fn)
	If (ErrorLevel=0)
	{
		MsgBox,48,"Error in My_OpenFile","Unable to open the file"
		return
	}
	Else
	{
		My_SetTitle(hEdit,hwnd)
		HistoryFile = %A_ScriptDir%\his\history.txt
		FileAppend , %fn%`n , %A_ScriptDir%\his\history.txt
		ControlFocus, ahk_id %hwnd%
	}
	return
}

My_GotoLine(hEdit, line){
	line_idx := HE_LineIndex(hEdit, line-1)
	HE_SetSel(hEdit, line_idx, line_idx)
	HE_ScrollCaret(hEdit )
;	HE_Scroll(hEdit,1,-1)
	return
}

My_ReplaceLine(hEdit,line,text){
	line_idx := HE_LineIndex(hEdit, line)
	HE_SetSel( hEdit, line_idx, line_idx+HE_LineLength(hEdit, line_idx))
	HE_ReplaceSel(hEdit, text)
}

My_IsRE(FindText){
	; Test if the FindText is a RE or not - can't be done as a regular find string may have dots
	If (RegExMatch(FindText, FindText))
		Return 0
	Else
		Return 1
}

My_GetBlock:
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
	; ToDo My_GetBlock - this fails on the last line of the file!
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

My_SendBlock:
	; Send the text
	HE_ReplaceSel(hEdit, Block)
	; Reselect the new block - may be a different length to the old block!
	HE_SetSel(hEdit,HE_GetSel(hEdit)-StrLen(Block),HE_GetSel(hEdit))
	return

My_GetAllText(hEdit){
	My_CMDCall("SelectMenu_All")
	Return HE_GetSelText(hEdit)
}

My_SendText(hEdit,Text){
	; First option - via the keyboard hook - slow and adds extra CTLF
	; SendInput, {raw} %Text%
	; Second option - message to hiEdit control directly
	SendMessage,0xC2,,&Text,,ahk_id %hEdit%
}

My_GetRelPath(CurrentFn,InsertFn) {
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

My_ToolsCall(hEdit,fnTool,param){
	; ToDo My_ToolsCall - this fails if param file name has spaces!
	Run, %fnTool% %A_Space% "%param%",""
}

My_ComspecCall(hEdit,fnTool,param,output,MyFilePath){
	IfExist, %fnTool%
	{
		Runwait, %ComSpec% /c %fnTool% %A_Space%  %param% > %output% , %MyFilePath% , Hide
	}
}

My_ViewHTML(FullFileName){

	; Init COM object
	Gui, 2:+LastFound +Resize +MinSize640x +MinSizex480
	Gui, 2:Show, w1020 h680, Code Viewer

	COM_AtlAxWinInit()
	pweb := COM_AtlAxCreateControl(WinExist(), "Shell.Explorer")
	COM_Invoke(pweb, "Navigate2", "file:///"FullFileName )
	Return

	Gui2Close:
	Gui, 2:Destroy
	COM_Release(pweb), COM_AtlAxWinTerm()
}

My_WinDisable:
	; Get current window
	 Winget, WindowID
	 WinSet, ExStyle, -0x20, ahk_id %WindowID%
	 WinSet, Disable,, ahk_id %WindowID%
	 GuiControl,, ToggleDisable, Enable
	return

My_WinEnable:
	; Get current window
	 Winget, WindowID
	 WinSet, Enable,, ahk_id %WindowID%
	 WinSet, ExStyle, -0x20, ahk_id %WindowID%
	 GuiControl,, ToggleDisable, Disable
	 WinActivate,  ahk_id %WindowID%
	return

My_FontInc:
    fStyle := "s" . (SubStr(fStyle, 2) + 1)
    HE_SetFont(hEdit, fStyle "," fFace)
    return

My_FontDec:
    fStyle := "s" . (SubStr(fStyle, 2) - 1)
    HE_SetFont(hEdit, fStyle "," fFace)
    return

;==================Callback Functions===================
; ToDo OnHiEdit - how to use?
OnHiEdit(Hwnd, Event, Info)
{
	OutputDebug % Hwnd " | " Event  " | " Info
}

;==================Shutdown Functions=================
GuiEscape:
	;My_CMDCall("FileMenu_Close")
	; Disabled to allow esc from message boxes
	return

GuiClose:
OnExit:
	My_CMDCall("FileMenu_Exit")
	ExitApp
	return

;==================Includes=========================
; Library files
#include inc\Attach.ahk
#include inc\COM.ahk
#include inc\Dlg.ahk
#include inc\HIEdit.ahk

; Print by Jballi
#include inc\HiEdit_Print.ahk

; Plugins - can't load dynamically
;  these are compiled into the exe.
#include plg\TabExpand.ahk
#include plg\Autocorrect.ahk
#include plg\Grammar.ahk
#include plg\DyslexicTypos.ahk
