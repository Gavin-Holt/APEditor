;  A Programmable Editor Gavin M Holt
; Standing upon the shoulders of giants
; 	"Developed " by borrowing from various scripts:
;		HiEdit.ahk				Antonis Kyprianou
;		HiEdit _test.ahk 		Magnetometer
;		AHKPAd				Michael Peters
;		Vic	Editor				Normand Lamoureux
;
; I have tried to avoid operations that load the whole file - preferring to process a line at a time
; Exceptions include:
;	Block:					If you "select all" the whole file is in memory
; 	FileMenu_OpenTemplate:		Read whole file in then inserts
; 	EditMenu_FindREDown:		Reads the rest of the file before each search
; 	InsertMenu_File:			Reads whole file in then inserts
;
; You may set #MaxMem to increase the maximum variable size from the default of 64MB
;
;==================Setup AHK Environment========================
#SingleInstance force
#NoEnv
#NoTrayIcon
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

;==================GUI Setup================================
; Set up the GUI object
Menu, TRAY, Icon, img/APEditor.png
Gui, +LastFound +Resize
hwnd := WinExist()
Gui, font, s11, Verdana   ; This does not seem to work with the menu fonts

; TOOLBAR  made of static pictures, no tooltips for speed!
WS_CLIPSIBLINGS = "0x4000000"
Gui, Margin, 0,0
Gui, Add, Picture, %WS_CLIPSIBLINGS%  HWNDToolBack x0 y0 w965 h44 BackgroundTrans,img/bluegrad.bmp
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

Gui, Add, Picture, gToolsMenu_XtreeShell x630 y7 BackgroundTrans, img/shellbutton.png
Gui, Add, Picture, gProjectMenu_Run x670 y6 w36 h36  BackgroundTrans, img/runbutton.png
Gui, Add, Picture, x710 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gFileMenu_Close x720 y7 BackgroundTrans, img/closebutton.png
Gui, Add, Picture, gEgg x760 y6 BackgroundTrans, img/sep.bmp

; MENUS - before display for speed?
My_MenuCreate()

; Default menu settings - perhaps an ini file in the future
Menu, FileMenu, Check, &Monitor
Menu, ViewMenu, Check, &Line Numbers
Menu, ViewMenu, Check, &Auto Indent
Menu, ViewMenu, Check, &Highlighting

; Custom menu settings
Gosub, MacrosMenu_Menu ; from #Included mac/Default.ahk
Gosub, PluginsMenu_Menu ; from #Included plg/Default.ahk

;==================HiEdit Control================================
; Set up the Hiedit control
hEdit := HE_Add(hwnd,0,44,965,636, "HSCROLL VSCROLL HILIGHT TABBEDBOTTOM FILECHANGEALERT")
fStyle := "s11" ,	fFace  := "Verdana"
HE_SetFont( hEdit, fStyle "," fFace)
HE_SetTabWidth(hEdit, 4)
; #include hes/DarkColours.hes ; make the colour matrix
#include hes/LightColours.hes ; make the colour matrix
HE_SetColors(hEdit, colours) ; assign to the edit control
HE_SetKeywordFile( "Highlights.hes")
HE_AutoIndent(hedit, true), autoIndent := true
HE_LineNumbersBar(hEdit, "automaxsize"), lineNumbers := true
; *** Statusbar do I want one?

; Show the GUI
Attach(hEdit, "w h")
Attach(ToolBack, "w")
Gui, Show, w965 h680, APEditor
Gui, Maximize
SetTimer, My_SetTitle, 50

;==================Load files from command line or Drag'n'Drop==============
; Handle files from command line
; *** Do we need a loop to cope with multiple input files
Input = %1%
If Input
{
	My_OpenFile(hEdit, Input)
}

;==================End of Autoexec Section===========================
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

;==================Hotkey Definitions===========================
SetTitleMatchMode, 2

#IfWinActive ahk_class  AutoHotkeyGUI

	^A::	My_CMDCall("SelectMenu_All")
	^B::	My_CMDCall("EditMenu_Matchbrace")
;	^C::	COPY!!!!
	^D::	My_CMDCall("BlockMenu_Duplicate")
	^E::	My_CMDCall("EditMenu_FindRE")
	^F::	My_CMDCall("EditMenu_Find")
	^G::	My_CMDCall("EditMenu_GoTo")
	^H::	My_CMDCall("FileMenu_OpenHistory")
	^I::	My_CMDCall("BlockMenu_Indent")
	^J::	My_CMDCall("BlockMenu_Join")
	^K::	My_CMDCall("QuicknDirty")
	^L::	My_CMDCall("FileMenu_SaveAll")
	^M::	My_CMDCall("NavigationMenu_Mark")
	^N::	My_CMDCall("FileMenu_New")
	^O::	My_CMDCall("FileMenu_OpenShortCut")
	^P::	My_CMDCall("FileMenu_Print")
	^Q::	My_CMDCall("FileMenu_Close")
	^R::	My_CMDCall("EditMenu_Replace")
	^S::	My_CMDCall("FileMenu_Save")
	^T::	My_CMDCall("FileMenu_OpenTemplate")
	^U::	My_CMDCall("EditMenu_PasteText")
;	^V::	PASTE
;	^W::	My_CMDCall("")
;	^X::	CUT
	^Y::	My_CMDCall("BlockMenu_Yank")
;	^Z::	UNDO

;	^+A::	SELECT ALL AND GOTO END
	^+B::	My_CMDCall("ProjectMenu_Backup")
	^+C::	My_CMDCall("EditMenu_CopyAppend")
	^+D::	My_CMDCall("ProjectMenu_Dir")
	^+E::	My_CMDCall("ProjectMenu_CodeExplorer")
	^+F::	My_CMDCall("ProjectMenu_FunctionList")
	^+G::	My_CMDCall("InsertMenu_GetFileName")
	^+H::	My_CMDCall("ProjectMenu_History")
	^+I::	My_CMDCall("InsertMenu_File")
	^+J::	My_CMDCall("ProjectMenu_JobsToDo")
	^+K::	My_CMDCall("InsertMenu_GetRelFileName")
	^+L::	My_CMDCall("FileMenu_SaveAll")
	^+M::	My_CMDCall("ProjectMenu_MakeIt")
	^+N::	My_CMDCall("InsertMenu_FileName")
;	^+O::
	^+P::	My_CMDCall("ProjectMenu_MapProject")
;	^+Q::
	^+R::	My_CMDCall("ProjectMenu_Run")
	^+S::	My_CMDCall("ProjectMenu_SearchDir")
	^+T::	My_CMDCall("ProjectMenu_TestIt")
	^+U::	My_CMDCall("InsertMenu_Bundle")
	^+V::	My_CMDCall("ProjectMenu_Versions")
	^+W::	My_CMDCall("SelectMenu_Word")
	^+X::	My_CMDCall("EditMenu_CutAppend")
;	^+Y::
;	^+Z::	UNDO

	^!A::	My_CMDCall("ToolsMenu_CCalc")
	^!B::	My_CMDCall("BookmarkMenu_Add")
	^!C::	My_CMDCall("ToolsMenu_Convert")
	^!D::	My_CMDCall("ToolsMenu_Diff")
	^!E::	My_CMDCall("ToolsMenu_Editor")
	^!F:: 	My_CMDCall("ToolsMenu_Filter")
	^!G::	My_CMDCall("ToolsMenu_GREP")
;	^!H::	My_CMDCall("ToolsMenu_HTMLEditor")
	^!I::		My_CMDCall("ToolsMenu_InternetSearch")
	^!J::		My_CMDCall("InsertMenu_SaveBundle")
	^!K::	My_CMDCall("BookmarkMenu_Clear")
	^!L::		My_CMDCall("BookmarkMenu_List")
;	^!M::	My_CMDCall("")
;	^!N::	My_CMDCall("")
	^!O::	My_CMDCall("ToolsMenu_Output")
;	^!P::	My_CMDCall("ToolsMenu_FTP")
;	^!Q::	My_CMDCall("")
	^!R::	My_CMDCall("EditMenu_Replaceinfiles")
	^!S::	My_CMDCall("ToolsMenu_SpellCheck")
;	^!T::		My_CMDCall("ToolsMenu_XtreeShell")
	^!U::	My_CMDCall("InsertMenu_EditBundle")
;	^!V::	My_CMDCall("ToolsMenu_W3Validator")
	^!W::	My_CMDCall("ToolsMenu_AWK")
	^!X::	My_CMDCall("ToolsMenu_HexEdit")
;	^!Y::
;	^!Z::

	^SC027::	My_CMDCall("PreMenu_1LineComment") ; ^;
	^SC02B::	My_CMDCall("PreMenu_2LineComment") ; ^#
	^/::		My_CMDCall("PreMenu_3LineComment") ; ^/
	^-::		My_CMDCall("PreMenu_4LineComment") ; ^-
	^;::		My_CMDCall("PreMenu_5LineComment") ; ^;

	^Space::	My_CMDCall("PreMenu_ClearPrefix")

	^F1::	My_CMDCall("HelpMenu_Context")
	F5::		My_CMDCall("FileMenu_Reload")
;	^F7::	My_CMDCall("MacrosMenu_Record")
;	^F8::	My_CMDCall("MacrosMenu_Play")
	F9::		My_CMDCall("EditMenu_FindNav")
	F10::	My_CMDCall("EditMenu_FindRENav")
	F11::	My_CMDCall("EditMenu_ReplaceNav")


	!Enter::	Send {Asc 010}    ; Alt+Enter
	+Enter::	SendInput <br>
	; ^Enter::	Seems to add line below

;	^Right::		Word Right
;	^Left::		Word Left

	!Right::	My_CMDCall("NavigationMenu_Next")
	!Left::	My_CMDCall("NavigationMenu_Prev")

	^!Right::	My_CMDCall("WindowsMenu_NextTab")
	^!Left::		My_CMDCall("WindowsMenu_PrevTab")

;	Up::		Up
;	Down::		Down

	+Up::		My_CMDCall("SelectMenu_LineUp")
	+Down::	My_CMDCall("SelectMenu_LineDown")

	^Up::		My_CMDCall("BlockMenu_ShiftUp")
	^Down::	My_CMDCall("BlockMenu_ShiftDown")

	!Up::		My_CMDCall("BookmarkMenu_Up")
	!Down::		My_CMDCall("BookmarkMenu_Down")

;	+!Up::
;	+!Down::

	^!Up::		My_CMDCall("EditMenu_FindUp") ; Cant call this command My_CMDCall("BlockMenu_ShiftUp") - WTF
	^!Down::	My_CMDCall("EditMenu_FindDown")

;	^DEL::		; 	Delete top next word
;	+DEL::		; 	BACKSPACE if not selection, ^X if there is a selection
;	^+DEL::	; 	Delete block

	^TAB::		Send {DEL}{TAB}
	^'::			SendInput &deg;
	+^.::		My_CMDCall("SelectMenu_Sentence")
	^8::		My_CMDCall("DevMenu_NextTask")
	!=::		My_CMDCall("DevEdit_Code")
	^=::		My_CMDCall("DevMenu_Reload")
	^7::		My_CMDCall("ToolsMenu_DPlusSearch")
#IfWinActive

;==================HiEdit Naviagtion Keys=======================
; 	+{Right} 	Extend a selection one character to the right. SHIFT+RIGHT ARROW
; 	+{Left} 	Extend a selection one character to the left. SHIFT+LEFT ARROW
; 	+^{Right}	Extend a selection to the end of a word. CTRL+SHIFT+RIGHT ARROW NB To the next word including W
; 	+^{Left}	Extend a selection to the beginning of a word. CTRL+SHIFT+LEFT ARROW
; 	+{End}		Extend a selection to the end of a line. SHIFT+END
; 	+{Home}	Extend a selection to the beginning of a line. SHIFT+HOME
; 	Over written see above	Extend a selection one line down. SHIFT+DOWN ARROW
; 	Over written see above	Extend a selection one line up. SHIFT+UP ARROW
; 	+{PgDn}	Extend a selection one screen down. SHIFT+PAGE DOWN
; 	+{PgUp}	Extend a selection one screen up. SHIFT+PAGE UP
; 	+^{Home}	Extend a selection to the beginning of a document. CTRL+SHIFT+HOME
; 	+^{End}	Extend a selection to the end of a document. CTRL+SHIFT+END
; 	^A			Extend a selection to include the entire document. CTRL+A
;
;==================Windows Global Keys=======================

;==================Menu Definitons===========================
My_MenuCreate(){

	Menu, FileMenu, Add, &New	^N,		MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Open...	^O,	MenuHandler
	Menu, FileMenu, Add, Open &Template...	^T,MenuHandler
	Menu, FileMenu, Add, Open &History...	^H,		MenuHandler
	Menu, FileMenu, Add, Re&load	F5,		MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Save	^S,		MenuHandler
	Menu, FileMenu, Add, Save &As...,		MenuHandler
	Menu, FileMenu, Add, Save A&ll	^L,	MenuHandler
	Menu, FileMenu, Add, Save S&election...,MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Monitor,		MenuHandler
	Menu, FileMenu, Add, Print...	^P,		MenuHandler
	Menu, FileMenu, Add,
	Menu, FileMenu, Add, &Close	^Q,		MenuHandler
	Menu, FileMenu, Add, E&xit,	MenuHandler

	; Submenus must be defined first!
	Menu, SelectMenu, Add, &Word	+^W,		MenuHandler
	Menu, SelectMenu, Add, &Line	+^Up/Down	,		MenuHandler
	Menu, SelectMenu, Add, &Sentence	+^.,	MenuHandler
	Menu, SelectMenu, Add, &All	^A,		MenuHandler

	Menu, BookmarkMenu, Add, &Add	^!B, MenuHandler
	Menu, BookmarkMenu, Add, &Clear	^!K, MenuHandler
	Menu, BookmarkMenu, Add
	Menu, BookmarkMenu, Add, &Up	!Up,	MenuHandler
	Menu, BookmarkMenu, Add, &Down	!Down, MenuHandler
	Menu, BookmarkMenu, Add
	Menu, BookmarkMenu, Add, &List...	^!L, MenuHandler
	Menu, BookmarkMenu, Add, &Save, MenuHandler

	Menu, NavigationMenu, Add, &Mark	^M, MenuHandler
	Menu, NavigationMenu, Add
	Menu, NavigationMenu, Add, &Next	!Right, MenuHandler
	Menu, NavigationMenu, Add, &Prev	!Left, MenuHandler

	Menu, FormatMenu, Add, &Upper Case, 	MenuHandler
	Menu, FormatMenu, Add, &Lower Case, 	MenuHandler
	Menu, FormatMenu, Add, &Reverse Case, MenuHandler
	Menu, FormatMenu, Add, &Proper Case, MenuHandler

	Menu, EOLMenu,Add, Win CRLF, MenuHandler
	Menu, EOLMenu,Add, Unix LF, MenuHandler
	Menu, EOLMenu,Add, Mac CR, MenuHandler

	Menu, EditMenu, Add, &Undo	^Z,			MenuHandler
	Menu, EditMenu, Add, R&edo	^Y,			MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Cut	^X,			MenuHandler
	Menu, EditMenu, Add, C&opy	^C,			MenuHandler
	Menu, EditMenu, Add, &Paste	^V,			MenuHandler
	Menu, EditMenu, Add, Paste &Text	^U, MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, Cut &Append	^+X,	MenuHandler
	Menu, EditMenu, Add, Copy Appen&d	^+C,	MenuHandler
	Menu, EditMenu, Add, Clip&board,		MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Goto...	^G,		MenuHandler
	Menu, EditMenu, Add, &Match brace	^B,	MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Find...	^F,			MenuHandler
	Menu, EditMenu, Add, FindR&E...	^E,		MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, Find Up	^!Up,	MenuHandler
	Menu, EditMenu, Add, Find Down	^!Down,MenuHandler
	Menu, EditMenu, Add, Find &List...,		MenuHandler
	Menu, EditMenu, Add, Find in files...,		MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Replace...	^R,	MenuHandler
	Menu, EditMenu, Add, Replace &in files	^!R,MenuHandler
	Menu, EditMenu, Add,
	Menu, EditMenu, Add, &Select,		:SelectMenu
	Menu, EditMenu, Add, &Bookmark,	:BookmarkMenu
	Menu, EditMenu, Add, &Navigation,	:NavigationMenu
	Menu, EditMenu, Add, C&hange Case,	:FormatMenu
	Menu, EditMenu, Add, Convert &EOL,		:EOLMenu

	; Submenus must be defined first!
	Menu, InsertMenu, Add, &Character...,	MenuHandler
	Menu, InsertMenu, Add, C&olour Scheme..., MenuHandler
	Menu, InsertMenu, Add, Colour &Picker..., MenuHandler
	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, &Date,		MenuHandler
	Menu, InsertMenu, Add, &Time,		MenuHandler
	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, File &Name	^+N,MenuHandler
	Menu, InsertMenu, Add, &Get FileName..	^+G,MenuHandler
	Menu, InsertMenu, Add, Get &Rel FileName..	^+K,MenuHandler
	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, &File...	^+I,	MenuHandler
	Menu, InsertMenu, Add, &Bundle...	^+U, MenuHandler
	Menu, InsertMenu, Add,
	Menu, InsertMenu, Add, Edit Bundle...	^!U, MenuHandler
	Menu, InsertMenu, Add, Save Bundle...	 ^!J, MenuHandler


	Menu, TrimMenu, Add, &RTrim, 		MenuHandler
	Menu, TrimMenu, Add, &LTrim, 		MenuHandler
	Menu, TrimMenu, Add, &FullTrim, 		MenuHandler
	Menu, TrimMenu, Add, &EmptyLines, 		MenuHandler

	Menu, SortMenu, Add, &Ascending, 	MenuHandler
	Menu, SortMenu, Add, &Descending, 	MenuHandler
	Menu, SortMenu, Add, &Integer, 		MenuHandler
	Menu, SortMenu, Add
	Menu, SortMenu, Add, &Remove Dups, MenuHandler

	Menu, PreMenu, Add, &Bullet, 		MenuHandler
	Menu, PreMenu, Add, &Number, 	MenuHandler
	Menu, PreMenu, Add, &Renumber, 	MenuHandler
	Menu, PreMenu, Add
	Menu, PreMenu, Add, 1 `; Line Comment, MenuHandler
	Menu, PreMenu, Add, 2 # Line Comment, MenuHandler
	Menu, PreMenu, Add, 3 // Line Comment, MenuHandler
	Menu, PreMenu, Add, 4 -- Line Comment, MenuHandler
	Menu, PreMenu, Add
	Menu, PreMenu, Add,  &Clear Prefix	^SPACE, MenuHandler

	Menu, BlockMenu, Add, &Indent	TAB, 	MenuHandler
	Menu, BlockMenu, Add, &Outdent	+TAB, 	MenuHandler
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, &Duplicate	^D, MenuHandler
	Menu, BlockMenu, Add, &Yank	^Y, 	MenuHandler
	Menu, BlockMenu, Add, &Join	^J, 	MenuHandler
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, Shift &Up	^Up, 	MenuHandler
	Menu, BlockMenu, Add, Shift &Down	^Down, MenuHandler
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, &Prefix,		:PreMenu
	Menu, BlockMenu, Add, &Sort, 		:SortMenu
	Menu, BlockMenu, Add, &Trim, 		:TrimMenu
	Menu, BlockMenu, Add
	Menu, BlockMenu, Add, &Winsorter...,MenuHandler

	Menu, MacrosMenu, Add, &Dir, 		MenuHandler
	Menu, MacrosMenu, Add, &Edit, 		MenuHandler
	Menu, MacrosMenu, Add, &Config,		MenuHandler
	Menu, MacrosMenu, Add
	Menu, MacrosMenu, Add, &Record	^F7,MenuHandler
	Menu, MacrosMenu, Add, &Play	^F8,MenuHandler
	Menu, MacrosMenu, Add
	Menu, MacrosMenu, Add, &Load		,MenuHandler
	Menu, MacrosMenu, Add, &Save		,MenuHandler
	Menu, MacrosMenu, Add, &Append	,MenuHandler
	Menu, MacrosMenu, Add

	Menu, PluginsMenu, Add, &Dir,		MenuHandler
	Menu, PluginsMenu, Add, &Edit, 		MenuHandler
	Menu, PluginsMenu, Add, &Config, 	MenuHandler

	Menu, PluginsMenu, Add

	Menu, ToolsMenu, Add, &Filter	^!F, MenuHandler
	Menu, ToolsMenu, Add, &Output	^!O, MenuHandler
	Menu, ToolsMenu, Add, Edi&tor	^!T, MenuHandler
	Menu, ToolsMenu, Add, He&x Edit	^!X, MenuHandler
	Menu, ToolsMenu, Add
	Menu, ToolsMenu, Add, &Diff...	^!D, MenuHandler
	Menu, ToolsMenu, Add, &GREP...	^!G,MenuHandler
	Menu, ToolsMenu, Add, A&WK...	^!W,MenuHandler
	Menu, ToolsMenu, Add
	Menu, ToolsMenu, Add, &Spellcheck	^!S,MenuHandler
	Menu, ToolsMenu, Add, &Convert	^!C,MenuHandler
	Menu, ToolsMenu, Add, CC&alc	^!A,MenuHandler 		; Cut list
	Menu, ToolsMenu, Add
	Menu, ToolsMenu, Add, Wo&rd Web	,MenuHandler 		; Cut list
	Menu, ToolsMenu, Add, &Internet Search	^!I,MenuHandler
	Menu, ToolsMenu, Add
	Menu, ToolsMenu, Add, &HTML Editor	, MenuHandler
	Menu, ToolsMenu, Add, HTML T&idy	,MenuHandler
	Menu, ToolsMenu, Add, W3 &Validator	,MenuHandler
	Menu, ToolsMenu, Add
	Menu, ToolsMenu, Add, &Webserver	,MenuHandler
	Menu, ToolsMenu, Add, FT&P	, 		MenuHandler
	Menu, ToolsMenu, Add, X&tree Shell	,MenuHandler

	Menu, ViewMenu, Add, &Auto Indent,		MenuHandler
	Menu, ViewMenu, Add, &Line Numbers,	MenuHandler
	Menu, ViewMenu, Add, &Highlighting,		MenuHandler
	Menu, ViewMenu, Add
	Menu, ViewMenu, Add, Tool&bar,			MenuHandler
	Menu, ViewMenu, Add, &Statusbar,		MenuHandler
	Menu, ViewMenu, Add
	Menu, ViewMenu, Add, &DevMenu,		MenuHandler

	Menu, OptionsMenu, Add, &Font,			MenuHandler
	Menu, OptionsMenu, Add, &Tabs,			MenuHandler
	Menu, OptionsMenu, Add, &Colours,		MenuHandler
	Menu, OptionsMenu, Add, Syta&x Colours,	MenuHandler
	Menu, OptionsMenu, Add
	Menu, OptionsMenu, Add, &View, 			:ViewMenu
	Menu, OptionsMenu, Add
	Menu, OptionsMenu, Add, F&ull Screen,	MenuHandler

	; Submenus must be defined first;
	Menu, DesktopMenu, Add, &Cascade,		MenuHandler
	Menu, DesktopMenu, Add, Tile &Vertical,MenuHandler
	Menu, DesktopMenu, Add, Tile &Horizontal,MenuHandler
	Menu, DesktopMenu, Add,
	Menu, DesktopMenu, Add, &Show desktop	,MenuHandler
	Menu, DesktopMenu, Add, &Multiple desktops,MenuHandler

	Menu, WindowsMenu, Add, Next Tab	^!Right,	MenuHandler
	Menu, WindowsMenu, Add, Prev Tab	^!Left,	MenuHandler
	Menu, WindowsMenu, Add, &File List 	,	MenuHandler
	Menu, WindowsMenu, Add,
	Menu, WindowsMenu, Add, &Desktop, :DesktopMenu

	Menu, ProjectMenu, Add, &Run	^+R, 	MenuHandler
	Menu, ProjectMenu, Add, &Makeit 	^+M, 		MenuHandler
	Menu, ProjectMenu, Add, &Testit	^+T, 		MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, Code E&xplorer	^+E, MenuHandler
	Menu, ProjectMenu, Add, &Function List	^+F,MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, &Dir 	^+D,	MenuHandler
	Menu, ProjectMenu, Add, &Search Dir	^+S,	MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, &Backup	^+B,	MenuHandler
	Menu, ProjectMenu, Add, &Versions	^+V,	MenuHandler
	Menu, ProjectMenu, Add, &History 	^+H,	MenuHandler
	Menu, ProjectMenu, Add
	Menu, ProjectMenu, Add, &Jobs Todo	^+J,MenuHandler
	Menu, ProjectMenu, Add, Map &Project 	^+P,	MenuHandler

	Menu, CodeFilelistMenu, Add, Add &file,	MenuHandler
;	Menu, CodeFilelistMenu, Add, Add dir,	MenuHandler
	Menu, CodeFilelistMenu, Add, Add &tree,	MenuHandler
	Menu, CodeFilelistMenu, Add, Add &all,	MenuHandler
	Menu, CodeFilelistMenu, Add
	Menu, CodeFilelistMenu, Add, Rem file,	MenuHandler
	Menu, CodeFilelistMenu, Add, Rem tree,	MenuHandler
	Menu, CodeFilelistMenu, Add, Rem all,	MenuHandler
	Menu, CodeFilelistMenu, Add
	Menu, CodeFilelistMenu, Add, View &list,	MenuHandler
	Menu, CodeFilelistMenu, Add, View &changes,	MenuHandler
	Menu, CodeFilelistMenu, Add, View &extras,	MenuHandler
	Menu, CodeFilelistMenu, Add
	Menu, CodeFilelistMenu, Add, &Clean extras,	MenuHandler
	Menu, CodeFilelistMenu, Add, &Sync (Addremove),	MenuHandler

	Menu, CodeVersionsMenu, Add, &Info,	MenuHandler
	Menu, CodeVersionsMenu, Add, &Diff,	MenuHandler
	Menu, CodeVersionsMenu, Add, &gDiff, MenuHandler
	Menu, CodeVersionsMenu, Add
	Menu, CodeVersionsMenu, Add, &Revert,	MenuHandler
	Menu, CodeVersionsMenu, Add


	Menu, CodeBranchMenu, Add, &New,	MenuHandler
	Menu, CodeBranchMenu, Add, &Select,	MenuHandler
	Menu, CodeBranchMenu, Add, &Merge,	MenuHandler
	Menu, CodeBranchMenu, Add, &Del,	MenuHandler

	Menu, LocalCodeMenu, Add, &New,		MenuHandler
	Menu, LocalCodeMenu, Add, N&est,		MenuHandler
	Menu, LocalCodeMenu, Add
	Menu, LocalCodeMenu, Add, &Open,		MenuHandler
	Menu, LocalCodeMenu, Add, &Commit,	MenuHandler
	Menu, LocalCodeMenu, Add, &Undo,		MenuHandler
	Menu, LocalCodeMenu, Add, Close,		MenuHandler
	Menu, LocalCodeMenu, Add
	Menu, LocalCodeMenu, Add, &Filelist...,	:CodeFilelistMenu
	Menu, LocalCodeMenu, Add, &Versions...,	:CodeVersionsMenu
	Menu, LocalCodeMenu, Add, &Branch...,	:CodeBranchMenu
	Menu, LocalCodeMenu, Add
	Menu, LocalCodeMenu, Add, &Status,	MenuHandler
	Menu, LocalCodeMenu, Add, Bro&wse,	MenuHandler
	Menu, LocalCodeMenu, Add, Console,	MenuHandler

	; Submenus must be defined first;
	Menu, RemoteCodeMenu, Add, &New,	MenuHandler
	Menu, RemoteCodeMenu, Add, &Open,	MenuHandler
	Menu, RemoteCodeMenu, Add, &Commit, MenuHandler
	Menu, RemoteCodeMenu, Add, Close,	MenuHandler
	Menu, RemoteCodeMenu, Add
	Menu, RemoteCodeMenu, Add, Clo&ne,	MenuHandler
	Menu, RemoteCodeMenu, Add, &Push,		MenuHandler
	Menu, RemoteCodeMenu, Add, Pu&ll,	MenuHandler
	Menu, RemoteCodeMenu, Add, &Sync,	MenuHandler
	Menu, RemoteCodeMenu, Add
	Menu, RemoteCodeMenu, Add, Status,	MenuHandler
	Menu, RemoteCodeMenu, Add, Bro&wse,	MenuHandler
	Menu, RemoteCodeMenu, Add, &Account,	MenuHandler

	; Submenus must be defined first;
	Menu, DevEdit, Add, &Code,		MenuHandler
	Menu, DevEdit, Add, &Menu,		MenuHandler
	Menu, DevEdit, Add, &Keys,		MenuHandler
	Menu, DevEdit, Add, Key&words,	MenuHandler
	Menu, DevEdit, Add
	Menu, DevEdit, Add, &Forms.AHK,	MenuHandler
	Menu, DevEdit, Add, HiEdit.&AHK,	MenuHandler
	Menu, DevEdit, Add, HiEdit.&INC,	MenuHandler

	Menu, DevMenu, Add, &Edit,		:DevEdit
	Menu, DevMenu, Add, &Reload,	MenuHandler
	Menu, DevMenu, Add, &Dir,		MenuHandler
	Menu, DevMenu, Add
	Menu, DevMenu, Add, E&vents,	MenuHandler
	Menu, DevMenu, Add, &Log,		MenuHandler
	Menu, DevMenu, Add
	Menu, DevMenu, Add, &Next Task	^*,MenuHandler
	Menu, DevMenu, Add, Dev &Map,	MenuHandler
	Menu, DevMenu, Add
	Menu, DevMenu, Add, &Compile,	MenuHandler
	Menu, DevMenu, Add, &Pack,		MenuHandler
	Menu, DevMenu, Add
	Menu, DevMenu, Add, &Hide,	MenuHandler

	; Submenus must be defined first;
	Menu, LocalDocsMenu, Add, &AHK, 	MenuHandler
	Menu, LocalDocsMenu, Add, &HTML, 	MenuHandler
	Menu, LocalDocsMenu, Add, &PHP, 	MenuHandler
	Menu, LocalDocsMenu, Add
	Menu, LocalDocsMenu, Add, &Others...,MenuHandler

	; Submenus must be defined first;
	Menu, WebDocsMenu, Add, &AHK, 	MenuHandler
	Menu, WebDocsMenu, Add, &HTML, 	MenuHandler
	Menu, WebDocsMenu, Add, &PHP, 	MenuHandler
	Menu, WebDocsMenu, Add,&TABLE,	MenuHandler
	Menu, WebDocsMenu, Add
	Menu, WebDocsMenu, Add, &Others..., MenuHandler

	Menu, HelpMenu, Add, &Menus,		MenuHandler
	Menu, HelpMenu, Add, &Keys,			MenuHandler
	Menu, HelpMenu, Add
	Menu, HelpMenu, Add, &Context...	^F1,	MenuHandler
	Menu, HelpMenu, Add, &Local Docs,	:LocalDocsMenu
	Menu, HelpMenu, Add, &Website Docs,	:WebDocsMenu
	Menu, HelpMenu, Add
	Menu, HelpMenu, Add, &Update,		MenuHandler
	Menu, HelpMenu, Add, &About,		MenuHandler

	Menu, MyMenuBar, Add,&File,			:FileMenu
	Menu, MyMenuBar, Add,&Edit,			:EditMenu
	Menu, MyMenuBar, Add,&Insert,		:InsertMenu
	Menu, MyMenuBar, Add,&Block,		:BlockMenu
	Menu, MyMenuBar, Add,&Macros,		:MacrosMenu
	Menu, MyMenuBar, Add,Plu&gins,		:PluginsMenu
	Menu, MyMenuBar, Add,&Tools,		:ToolsMenu
	Menu, MyMenuBar, Add,&Project,		:ProjectMenu
	Menu, MyMenuBar, Add,&LocalCode,	:LocalCodeMenu
	Menu, MyMenuBar, Add,&RemoteCode,	:RemoteCodeMenu
	Menu, MyMenuBar, Add,&Options,		:OptionsMenu
	Menu, MyMenuBar, Add,&Windows,	:WindowsMenu
	Menu, MyMenuBar, Add,&Help,		:HelpMenu
	Menu, MyMenuBar, Color,  FFFFFFFF
	Gui, Menu, MyMenuBar
}

; Menu Handler and supporting functions
MenuHandler:
	; Uses the name of the menu and item to call a subroutine
	;    after clearing out unwanted menu formatting
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
;	msgbox, %MenuLabel%
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
	MsgBox,48,"Easter Egg","OK now I have egg on my face"
	return

QuicknDirty:
	Sel := HE_GetSelText(hEdit)
	iText = [tostring(%Sel%)] = "%Sel%"
	My_SendText(hEdit,iText)
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

FileMenu_OpenHistory:
	HistoryFile = %A_ScriptDir%\his\history.txt
	If FileExist(HistoryFile){
		HE_OpenFile(hEdit,HistoryFile)
			If (ErrorLevel=0)
			{
				MsgBox,48,"Error in My_OpenFile","Unable to open the file"
			}
			Else
			{
				My_SetTitle(hEdit,hwnd)
				ControlFocus, ahk_id %hwnd%
				Send ^{End}
				Send {Up}
				Send +{End}
				Send ^{End}
				Send {Up}
				Send +{End}
			}
	} Else {
		MsgBox, No File History
	}
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
	; *** FileMenu_Monitor - this is already set but I have no event call back function
	return

FileMenu_Reload:
	HE_ReloadFile(hEdit)
	return

FileMenu_Print:
	HE_Print(hEdit)
	Return

FileMenu_Close:
	If HE_GetModify(hEdit,-1)
	{
		My_FileName :=  HE_GetFileName(hEdit)
		msgbox,  4, %My_FileName% , File not saved. Do you want to save before closing?
		IfMsgBox, Yes
 			My_CMDCall("FileMenu_Save")
	}
	HE_CloseFile(hEdit, -1)
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
	Runwait, "P:\MyPrograms\EDITORS\Addins\getplaintext\getplaintext.exe"
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

EditMenu_Clipboard:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\ClipTrap\ClipTrap.exe","")
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
		Gosub, NavigationMenu_Mark
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

EditMenu_Matchbrace:
	; Will need a keyboard shortcut
	; *** EditMenu_Matchbrace not done yet
	return


EditMenu_FindNav:
	; Mark postion for navigation
	GoSub, NavigationMenu_Mark

EditMenu_Find:
	; Gosub, My_GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
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

EditMenu_FindRENav:
	; Mark postion for navigation
	GoSub, NavigationMenu_Mark

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

EditMenu_FindList:
	If (MyLastFind = "RE") {
		GoSub, EditMenu_FindREList
		return
	}
	If (MyLastFind = "Text") {
		GoSub, EditMenu_FindTList
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

EditMenu_FindTList:
	; Generate the MyFile and MySep variables
	GoSub, My_GetLineNumber
	SearchMatches%MyFile% = ""

	; Init fp and fl
	fp := 0
	fl := HE_GetTextLength(hEdit)
	Loop
	{
		nfp := HE_FindText(hEdit, FindText, fp, -1, Flags)
		; Break if no matches
		If (nfp = -1 or nfp = 4294967295){
			break
		}

		;Convert to line numbers
		ln := HE_LineFromChar(hEdit, nfp) +1

		; Generate a list of matches
		If (SearchMatches%MyFile% < 1) {
			; First entry in the list
			SearchMatches%MyFile%	 := ln A_Space HE_GetLine(hEdit, ln-1)
		} Else {
			SearchMatches%MyFile%	 :=  SearchMatches%MyFile% MySep ln A_Space HE_GetLine(hEdit, ln-1)
		}

		; Break at end of file
		fp := nfp + StrLen(FindText)
		If (fp > fl) {
			break
		}
	}

	; *** EditMenu_FindTList - would prefer to have a list with an input box for goto.
	Msgbox, 8192, %MyFile% , % "Matches for " FindText MySep MySep SearchMatches%MyFile%
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

EditMenu_FindREList:
	; Generate the MyFile and MySep variables
	GoSub, My_GetLineNumber
	SearchMatches%MyFile% = ""

	; Add options to return found position
	; Assume already done?
	; REFindText := "P)" . FindText

	; Init fp and fl
	fp := 1
	fl := HE_GetTextLength(hEdit)
	Loop
	{
		nfp := RegExMatch(MyText, REFindText, REMatchLen, fp)
		If ErrorLevel 	{
			break
		}
		; Break if out of bounds
		If (nfp < 1 or nfp > 4294967295) {
			break
		}

		;Convert to line numbers
		ln := HE_LineFromChar(hEdit, nfp) +1

		; Generate a list of matches
		If (SearchMatches%MyFile% < 1) {
			; First entry in the list
			SearchMatches%MyFile%	 := ln A_Space HE_GetLine(hEdit, ln-1)
		} Else {
			SearchMatches%MyFile%	 :=  SearchMatches%MyFile% MySep ln A_Space HE_GetLine(hEdit, ln-1)
		}

		; Increment fp
		;  adding REMatchLen would seem nice but what if this is zero?
		fp := nfp + 1
		; Break at end of file
		If (fp > fl) {
			break
		}
	}

	; *** EditMenu_FindREList - would prefer to have a list with an input box for goto.
	Msgbox, 8192, %MyFile% , % "Matches for " FindText MySep MySep SearchMatches%MyFile%

	return

EditMenu_Findinfiles:
	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	} Else {
		FindText := Sel
	}

	Run, P:\MyPrograms\EDITORS\Addins\TextGrepWin\gwFindReplace.exe /portable /searchpath:"%MyFilePath%" /filemask:"%MyFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
	return

EditMenu_ReplaceNav:
	; Mark postion for navigation
	GoSub, NavigationMenu_Mark

EditMenu_Replace:
	; GoSub, NavigationMenu_Mark
	; Gosub, My_GetFilePath ; If called from the toolbar we will miss these instructions

	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Target:= Sel
		ReplaceText:=""
	} Else {
		ReplaceText:= Sel
		Target:=""

	}

	; Loop back point
	ReplaceLoop:

	; Ask for text to find - modal dialog
	Gui, +OwnDialogs
	InputBox, ReplaceCMD, Replace, Enter sub command (find|replace|[&All]), , 400, 120, , , , ,%ReplaceCMD%
	if ErrorLevel
		return

	; Split the command string
	RepArray1 := ""
	RepArray2 := ""
	RepArray3 := ""
	StringSplit, RepArray, ReplaceCMD , |
	FindText 	:= RepArray1
	ReplaceText	:= RepArray2
	ReplaceOptions	:= RepArray3

	; Check commands
	If (RepArray0 < 2){
		msgbox, Too few parameters
		return
	}
	If ( FindText=""){
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

	; If [all] then do all in selection (or whole file)
	If (ReplaceOptions="All" or ReplaceOptions="all"  or ReplaceOptions="ALL"){
		If (Target="") {
			; *** Problem getting it to select whole document
			HE_SetSel(hEdit, 0, -1)
			Target := HE_GetSelText(hEdit)
			StringReplace, Output, Target, %FindText%, %ReplaceText%, All
			HE_ReplaceSel(hEdit,Output)
		} Else {
			StringReplace, Output, Target, %FindText%, %ReplaceText%, All
			HE_ReplaceSel(hEdit,Output)
		}
	}

	; If [global] then do all in every tab
	If (ReplaceOptions="global"){
		; *** Do replace in all open files
	}
	return

EditMenu_Replaceinfiles:
	gosub, ToolsMenu_GREP
	return

SelectMenu_Word:
	MouseMove, %A_CaretX%, %A_CaretY%
	Send, {LButton}{LButton}
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

SelectMenu_Sentence:
	; *** Select sentence - is there much point without text wrapping?

	; Search left for break

	; Search right for break

	; Select text

	return

SelectMenu_All:
	HE_SetSel(hEdit, 0, -1)
	return

BookmarkMenu_Add:
	GoSub, My_GetLineNumber
	If (Bookmarks%MyFile% < 1) {
		Bookmarks%MyFile% := MyLineNumber
	} Else {
		Bookmarks%MyFile% :=  Bookmarks%MyFile% MySep MyLineNumber
		Sort, Bookmarks%MyFile%, NU
	}
	return

BookmarkMenu_Clear:
	GoSub, My_GetLineNumber
	Bookmarks%MyFile% :=
	return

BookmarkMenu_Up:
	GoSub, My_GetLineNumber
	Pointer := 0
	Loop, Parse, Bookmarks%MyFile% , `n
	{
		If (A_LoopField < MyLineNumber){
			Pointer := A_LoopField
		} Else {
			If (Pointer > 0)
				My_GotoLine(hEdit,Pointer)
			break
		}
	}
	return

BookmarkMenu_Down:
	GoSub, My_GetLineNumber
	Loop, Parse, Bookmarks%MyFile% , `n
	{
		If (A_LoopField > MyLineNumber){
			My_GotoLine(hEdit,A_LoopField)
			break
		}
	}
	return

BookmarkMenu_List:
	GoSub, My_GetLineNumber
	Msgbox, 8192, Bookmarks , % "For : " MyFile MySep  Bookmarks%MyFile%
	return

BookmarkMenu_Save:
	GoSub, My_GetLineNumber
	HE_NewFile(hEdit)
	My_SendText(hEdit, Bookmarks%MyFile% )
	return

NavigationMenu_Mark:
	GoSub, My_GetLineNumber
	; Store in a variable - glup another global pointer!!
	NavIndex++
	Navigation%NavIndex% :=  MyFilePath . "\" . MyFileName . "@" . MyLineNumber
	return

NavigationMenu_Prev:
	If (NavIndex > 0) {
		My_GotoNav(Navigation%NavIndex%)
		NavIndex--
	} Else {
		NavIndex = 1
	}
	return

NavigationMenu_Next:
	NavIndex++
	If (Navigation%NavIndex% <> "") {
		My_GotoNav(Navigation%NavIndex%)
	} Else {
		NavIndex--
	}
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
	;*** EOLMenu_UnixLF
	return

EOLMenu_MacCR:
	;*** EOLMenu_MacCR
	return

EOLMenu_WinCRLF:
	; Remember the current position
	CurrChar := HE_LineIndex(hEdit, -1)

	; Break types - created outside the Loop!
	HardBreak 	:= Chr(13) . Chr(10)		;CRLF 	`r`n
	SoftBreak 	:= Chr(10)				;LF		`n
	EOF			:= "" ; Can't make Chr(0) . Chr(0)

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
	HE_SetSel(hEdit,CurrChar,CurrChar)
	HE_ScrollCaret(hEdit)
	return

InsertMenu_Character:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\extrakeys\extrakeys.exe","")
	return

InsertMenu_ColourPicker:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\ColourPicker\ColourPicker.exe","")
	return

InsertMenu_ColourScheme:
	My_ToolsCall(hEdit,"P:\MyPrograms\WEB\Firefox\FirefoxPortable.exe","http://colorschemedesigner.com/")
	return

InsertMenu_Date:
	FormatTime,date,YYYYMMDDHH24MISS,dd-MM-yyyy
	My_SendText(hEdit,date)
	return

InsertMenu_Time:
	FormatTime,time,YYYYMMDDHH24MISS,HH':'mm
	My_SendText(hEdit,time)
	return

InsertMenu_File:
	FileSelectFile, ifn, 3, %MyFilePath%, Insert file contents
	FileRead, iText, %ifn%
	My_SendText(hEdit,iText)
	return

InsertMenu_Bundle:

	If (MyFileExt=""){
		FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\, Parse bundle file
	}Else {
		If (MyFileExt="html" or MyFileExt="htm" or MyFileExt="htt" or MyFileExt="hti" ){
			FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\html\, Parse bundle file
		} Else If (MyFileExt="hhc" ) {
			FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\hhc, Parse bundle file
		} Else {
			FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\, Parse bundle file
		}
	}

	If (FileExist(BundleFile)) {
		My_ParseBundle(hEdit,BundleFile)
	}
	return

InsertMenu_EditBundle:
	If (MyFileExt=""){
		FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\, Edit bundle file
	}Else {
		If (MyFileExt="html" or MyFileExt="htm" or MyFileExt="htt" or MyFileExt="hti" ){
			FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\html\, Edit bundle file
		} Else {
			FileSelectFile, BundleFile, 3, %A_ScriptDir%\snp\, Edit bundle file
		}
	}

	If (FileExist(BundleFile)) {
	My_OpenFile(hEdit,BundleFile)
	}

	return

InsertMenu_SaveBundle:
	FileSelectFile, fn, S 16, %A_ScriptDir%\snp\ , Save File As..
	if (Errorlevel)
		return
	HE_SaveFile(hEdit, fn, -1)
	HE_SetModify(hEdit, 0)
	My_SetTitle(hEdit,hwnd)
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

BlockMenu_BlockComment:
	Gosub, My_GetBlock
	Block := "/*" . A_Tab . Block . A_Tab . "*/"
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
	;My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe", A_ScriptDir . "\mac\")
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
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\APEditor\plg\Macro.exe","")
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
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\APEditor\plg\Macro.exe",fn)
	return

MacrosMenu_Save:
	FileSelectFile, fn, S 16, %A_ScriptDir%\mac , Save Macro As.., *.mac
	if (Errorlevel) {
		return
	}
	FileCopy, %A_ScriptDir%\plg\Macro.ini, %fn%
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\APEditor\plg\Macro.exe",fn)
	return

MacrosMenu_Append:
	FileSelectFile, fn, S 1, %A_ScriptDir%\..\mac , Save Macro As.., *.mac
	if (Errorlevel)
		return
	IniRead,macro,%A_ScriptDir%\Macro.ini,Settings,macro
	FileAppend, %macro%, %fn%
	Sleep, 50
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\APEditor\plg\Macro.exe",fn)
	return

PluginsMenu_Dir:
	;My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe",A_ScriptDir . "\plg\")
	Run, explorer.exe /e`,/root`,	%A_ScriptDir%\plg\
	return

PluginsMenu_Edit:
	FileSelectFile, fn, 3, %A_ScriptDir%\plg\ , Open a file
	if Errorlevel
		return
	My_OpenFile(hEdit, fn)
	return

PluginsMenu_Config:
	My_OpenFile(hEdit, A_ScriptDir . "\plg\default.ahk")
	return

ToolsMenu_Filter:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\TextFilter\TextFilter.exe",HE_GetFileName(hEdit))
	return

ToolsMenu_Editor:
	My_CMDCall("FileMenu_Save")
	; My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\wscihun\SciTELite.exe",HE_GetFileName(hEdit))
	;My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\FocusWriter\FocusWriter.exe",HE_GetFileName(hEdit))
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Editor3\TedNpad.exe",HE_GetFileName(hEdit))
	return

ToolsMenu_Diff:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\TextDiff\TextDiff.exe",HE_GetFileName(hEdit))
	return

ToolsMenu_GREP:
	; If text is selected and no new lines, then search with it
	Sel:= HE_GetSelText(hEdit)
	If Sel contains `r,`n
	{
		Sel:=""
	} Else {
		FindText := Sel
	}

	My_CMDCall("FileMenu_Save")
	Gosub, My_WinDisable
	Runwait, P:\MyPrograms\EDITORS\Addins\TextGrepWin\gwFindReplace.exe /portable /searchpath:"%MyFilePath%" /filemask:"%MyFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
	Gosub, My_WinEnable
	Gosub, FileMenu_Reload
	Gosub, NavigationMenu_Prev

	return

ToolsMenu_AWK:
	Gosub, My_GetBlock

	FileSelectFile, TScript, 3, %A_ScriptDir%\tsc\, Transformation script
	SplitPath, TScript, , ,TScriptExt

	If (FileExist(TScript) and (TScriptExt="AWK")) {
		FileDelete, %A_ScriptDir%\tsc\temp.txt
		FileAppend, Block, %A_ScriptDir%\tsc\temp.txt
		msgbox, %TScript%
		; *** EditMenu_AWK  This is not finished!
	}

	Gosub, My_SendBlock
	return

ToolsMenu_Output:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\TextShowTx\ShowTx.exe",HE_GetFileName(hEdit))
	return

ToolsMenu_HexEdit:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\HexD\HxD.exe",HE_GetFileName(hEdit))
	;My_ToolsCall(hEdit,"P:\MyPrograms\SHELLS\zX32\viewer\h32.exe",HE_GetFileName(hEdit))
	return

ToolsMenu_SpellCheck:
	My_CMDCall("FileMenu_Save")
	Gosub, My_WinDisable
	If (MyFileExt="html" or MyFileExt="htm" or MyFileExt="htt" or MyFileExt="hti" ){
		Runwait, %ComSpec% /c P:\MyPrograms\EDITORS\Addins\Hunspell\hunspell.exe -d P:\MyPrograms\EDITORS\Addins\Dictionary\en_GB -p P:\MyPrograms\EDITORS\Addins\Dictionary\USER_DICT.dic -H "%MyFilePath%\%MyFileName%" && pause
	} Else {
		Runwait, %ComSpec% /c P:\MyPrograms\EDITORS\Addins\Hunspell\hunspell.exe -d P:\MyPrograms\EDITORS\Addins\Dictionary\en_GB -p P:\MyPrograms\EDITORS\Addins\Dictionary\USER_DICT.dic "%MyFilePath%\%MyFileName%" && pause
	}
	Gosub, My_WinEnable
	Gosub, FileMenu_Reload
	return

ToolsMenu_WordWeb:
	My_ToolsCall(hEdit,"C:\windows\system32\Rundll32.exe "," P:\MyPrograms\EDITORS\Addins\Wordweb\WWEB32.DLL,ShowRunDLL " . HE_GetSelText(hEdit))
	return

ToolsMenu_Convert:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Convert\radix.exe",HE_GetSelText(hEdit))
	return

ToolsMenu_CCalc:
	FileDelete, P:\MyPrograms\DEV\CCalc\input.txt
	Sel := HE_GetSelText(hEdit)
	FileAppend ,  %Sel%,  P:\MyPrograms\DEV\CCalc\input.txt
	My_ToolsCall(hEdit,"P:\MyPrograms\DEV\CCalc\CCalc.exe", " P:\MyPrograms\DEV\CCalc\input.txt" )
	return

ToolsMenu_HTMLEditor:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\HTMLEdit\htmledit.exe",HE_GetFileName(hEdit))
	return

ToolsMenu_HTMLTidy:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\HTMLTidyGUI\tidyGUI.exe",  -f HE_GetFileName(hEdit) -c "P:\MyPrograms\EDITORS\addins\HTMLTidyGUI\NoWrap.ini")
	return

ToolsMenu_W3Validator:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\W3Validate\sp\validate.bat",HE_GetFileName(hEdit))
	return

ToolsMenu_InternetSearch:
	sText := RegExReplace(HE_GetSelText(hEdit), "\s" , "%20")
	If (SubStr(sText, 1, 3) = "htt" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe",sText)
	} Else {
		My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe","http://www.google.co.uk/search?q=" .  sText)
	}
	return

ToolsMenu_DPlusSearch:
	sText := RegExReplace(HE_GetSelText(hEdit), "\R" , "")
	sText := RegExReplace(sText, "\s" , "%20")
	Run, "P:\MyPrograms\WEB\DPlus\dplus.exe" %A_Space% %sText%,"P:\MyPrograms\WEB\DPlus\"
	return

ToolsMenu_Webserver:
	My_ToolsCall(hEdit,"P:\MyPrograms\SERVER\Mongoose\mongoose-3.4.exe",""	)
	My_ToolsCall(hEdit,"P:\MyPrograms\WEB\Firefox\FirefoxPortable.exe","http://localhost:8080/" .  SubStr(MyFilePath, 3) . "/" . MyFileName)
	return

ToolsMenu_FTP:
	My_ToolsCall(hEdit,"P:\MyPrograms\SHELLS\FTPx\FTPX.EXE",""	)
	return

ToolsMenu_XTreeShell:
	; Reset FileName as can be called called from button bar
	Gosub, My_GetFilePath
	Run, P:\MyPrograms\SHELLS\zX32\bin\cmd_patched.exe /c P:\MyPrograms\SHELLS\zX32\x32.exe  %MyFilePath%
	;Run, P:\MyPrograms\SHELLS\zX32\x32.exe , %MyFilePath%
	return

ProjectMenu_Dir:
	My_ToolsCall(hEdit, "P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe", MyFilePath)
	; MyExplorerPath = %MyFilePath% . "\.."
	; Run, explorer.exe /e`,/root`,	%MyExplorerPath%
	return

ProjectMenu_Run:
	; Save the file
	My_CMDCall("FileMenu_Save")

	; Prun will only take a single parameter!
	If (MyFileExt = "php" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\SERVER\Mongoose\mongoose-3.4.exe",""	)
		My_ToolsCall(hEdit,"P:\MyPrograms\WEB\Firefox\FirefoxPortable.exe","http://localhost:8080/" .  SubStr(MyFilePath, 3) . "/" . MyFileName)
	} Else If (MyFileExt = "pl" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\ploticus\bin\pl.exe","-errfile P:\MyPrograms\DEV\ploticus\bin\pl.out -svg " . HE_GetFileName(hEdit))
	} Else If (MyFileExt = "m" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\Matlab\MatLab.bat ",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "lua" ) {
		My_ToolsCall(hEdit,"P:\MyProjects\LuaDE\bin\RunLua.bat",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "py" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\PPython\python.bat ",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "inp" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\gretl\gretl.bat ",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "ccl" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\CCalc\CCalc.exe",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "ds" ) {
		My_ComspecCall(hEdit,"P:\MyPrograms\DEV\DScript\ds.exe",HE_GetFileName(hEdit), MyFilePath . "\output.txt", MyFilePath)
	} Else If (MyFileExt = "js" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\js_shell\js.bat",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "ahk" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\AutoHotKey\AutoHotkey.exe",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "lps" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\DEV\Logparser\LogParser.bat",HE_GetFileName(hEdit))
	} Else If (MyFileExt = "awk" ) {
		My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\gawk\awk.bat",HE_GetFileName(hEdit))
	} Else {
		My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe",HE_GetFileName(hEdit))
	}
	return

ProjectMenu_Makeit:
	My_CMDCall("FileMenu_SaveAll")
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe",MyFilePath . "\MakeIt.bat")
	return

ProjectMenu_Testit:
	My_CMDCall("FileMenu_SaveAll")
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe",MyFilePath . "\TestIt.bat")
	return

ProjectMenu_SearchDir:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Astrogrep\Astrogrep.exe",MyFilePath)
	return

ProjectMenu_CodeExplorer:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\TextView\Textview.exe ",HE_GetFileName(hEdit))
	return

ProjectMenu_JobsTodo:
	My_OpenFile(hEdit, MyFilePath .  "\Todo.txt")
	return

ProjectMenu_MapProject:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Blumind\Blumind.exe.bat",MyFilePath . "\main.bmd")
	return

ProjectMenu_FunctionList:
	msgbox, Create a list of functions
	return

ProjectMenu_Backup:
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

ProjectMenu_History:
	MyBackupPath := MyFilePath . "\zBackup\"
	IfNotExist, %MyBackupPath%
	{
		msgbox, No backup directory
		return
	} Else {
		Run, ..\Addins\TextView\Textview.exe, %MyBackupPath%
	}
	return

ProjectMenu_Versions:
	MyBackupPath := MyFilePath . "\zBackup\"
	FileSelectFile, fn, 3,  %MyBackupPath%,  "Select a backup file ...", (*%MyFileName%)
	If Errorlevel
		return
	My_OpenFile(hEdit, fn)
	return

LocalCodeMenu_New:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat new %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Open:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat open %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Nest:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat newnest -nested %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Commit:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat commit %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Undo:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat undo %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Close:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat close %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Status:
	Run, %A_ScriptDir%\bin\Console.exe -t CMD_PATCHED -r " /k %A_ScriptDir%\bin\fossil.bat status %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Browse:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat browse %MyFilePath%\%MyFileName%"
	return

LocalCodeMenu_Console:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED , %MyFilePath%
	return

CodeFilelistMenu_Addfile:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat addfile %MyFilePath%\%MyFileName%"
	return

; CodeFilelistMenu_Adddir:
; 	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat adddir %MyFilePath%\%MyFileName%"
; 	return

CodeFilelistMenu_Addtree:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat addtree %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_Addall:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat addtree %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_ViewList:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat viewlist %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_ViewChanges:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat viewchanges %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_ViewExtras:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat viewextras %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_CleanExtras:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat cleanextras %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_Sync(AddRemove):
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat addremove %MyFilePath%\%MyFileName%"
	return

CodeFilelistMenu_Browse:
	Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat browse %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_New:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotenew %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Open:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remoteopen %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Commit:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotecommit %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Close:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat close %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Push:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotepush %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_clone:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remoteclone %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Pull:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotepull %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Sync:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotesync %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Status:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotestatus %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Browse:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remotebrowse %MyFilePath%\%MyFileName%"
	return

RemoteCodeMenu_Account:
		Run, P:\MyPrograms\SHELLS\Console2\Console.exe -t CMD_PATCHED -r "/k %A_ScriptDir%\bin\fossil.bat remoteaccount %MyFilePath%\%MyFileName%"
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
	; *** OptionsMenu_Colours
	return

OptionsMenu_SytaxColours:
	FileSelectFile, fn, 3, %A_ScriptDir%\hes, "Select a syntax highlight file ...", (*.hes)
	HE_SetKeywordFile(fn)
	return

OptionsMenu_FullScreen:
	WinMaximize, ahk_id %hwnd%
	return

ViewMenu_Autoindent:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	HE_AutoIndent(hEdit, autoIndent := !autoIndent)
	return

ViewMenu_LineNumbers:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	lineNumbers := !lineNumbers
	HE_LineNumbersBar(hEdit, lineNumbers ? "automaxsize" : "hide")
	return

ViewMenu_Highlighting:
	; *** ViewMenu_Highlighting
	return

ViewMenu_Toolbar:
	; *** ViewMenu_Toolbar
	return

ViewMenu_Statusbar:
	; *** ViewMenu_Statusbar
	return

ViewMenu_DevMenu:
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
	Menu, MyMenuBar, Add,&Dev,		:DevMenu
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

DesktopMenu_Cascade:
	My_ToolsCall(hEdit,"P:\MyPrograms\SHELLS\Addins\vDesktop\TileWindows.exe","-c")
	return

DesktopMenu_TileVertical:
	My_ToolsCall(hEdit,"P:\MyPrograms\SHELLS\Addins\vDesktop\TileWindows.exe","-v")
	Return

DesktopMenu_TileHorizontal:
	My_ToolsCall(hEdit,"P:\MyPrograms\SHELLS\Addins\vDesktop\TileWindows.exe","-h")
	Return

DesktopMenu_Showdesktop:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe","P:\MyPrograms\SHELLS\Addins\showDesktop.scf")
	Return

DesktopMenu_Multipledesktops:
	My_ToolsCall(hEdit,"P:\MyPrograms\SHELLS\Addins\vDesktop\desktops.exe"," /accepteula")
	Return

LocalDocsMenu_AHK:
	Run, "P:\MyPrograms\DEV\AutoHotKey\AutoHotkey.chm"
	return

LocalDocsMenu_HTML:
	Run, "P:\MyPrograms\EDITORS\Addins\Help\HTML\htmlref.chm"
	return

LocalDocsMenu_PHP:
	Run, "P:\MyPrograms\EDITORS\Addins\Help\PHP\php_manual_en.chm"
	return

LocalDocsMenu_Others:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe", "P:\MyPrograms\EDITORS\Addins\Help")
	return

WebDocsMenu_AHK:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe","http://www.autohotkey.com/board/index.php?app=core&module=search&search_in=forums")
	return

WebDocsMenu_TABLE:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe","http://accessify.com/tools-and-wizards/accessibility-tools/table-builder/")
	return

WebDocsMenu_HTML:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe", "P:\MyPrograms\EDITORS\Addins\Help\HTML\")
	return

WebDocsMenu_PHP:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe", "P:\MyPrograms\EDITORS\Addins\Help\PHP\")
	return

WebDocsMenu_Others:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe", "P:\MyPrograms\EDITORS\Addins\Help\")
	return

HelpMenu_Contents:
	; *** HelpMenu_Contents
	return

HelpMenu_Keys:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\gawk\awk.bat","P:\MyPrograms\EDITORS\APEditor\doc\Keys.awk")
	My_OpenFile(hEdit,"P:\MyPrograms\EDITORS\APEditor\doc\Keys.txt")
	return

HelpMenu_Context:
	sText := HE_GetSelText(hEdit)

	If (MyFileExt="AHK")
	{
		If sText
		{
			My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Help\ChmKw.exe","P:\MyPrograms\DEV\AutoHotKey\AutoHotkey.chm::/docs/commands/" . sText . ".htm")
		} Else {
			My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Help\ChmKw.exe","P:\MyPrograms\DEV\AutoHotKey\AutoHotkey.chm::/docs/AutoHotkey.htm")
		}
	}

	If (MyFileExt="HTML" or MyFileExt="HTP" or MyFileExt="HTT")
	{
		If sText
		{
			My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Help\ChmKw.exe","P:\MyPrograms\EDITORS\Addins\Help\HTML\htmlref.chm::/olist.html")
		} Else {
			My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Help\HTML\htmlref.chm","")
		}
	}

	return
	;*** I don't have a CHM file for HTML / PHP with pages matching function names!

HelpMenu_Update:
	; *** HelpMenu_Update
	return

HelpMenu_About:
	msg := "A programmable editor`n`n"
		. "For more information visit: www.winasm.net`n`n"
		. "  HiEdit by Akyprian`n"
		. "  AHK wrapper by Majkinetor`n"
		. "  Editor functionality by GavinH"
	MsgBox, 48, About, %msg%
	return

DevMenu_Reload:
	;My_CMDCall("ProjectMenu_Backup")
	My_CMDCall("FileMenu_SaveAll")
	Reload
	HE_ScrollCaret(hEdit )
	return

DevMenu_Dir:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Addins\Prun\PRun.exe",A_ScriptDir)
	return

DevMenu_Events:
	HE_SetEvents(hEdit, "OnHiEdit", "SelChange Scroll Key Mouse ContextMenu")
	MsgBox, Open DebugView to monitor events.
	return

DevMenu_Log:
	; *** DevMenu_Log
	return

DevMenu_NextTask:
	FindText := "***"
	MyLastFind := "Text"
	GoSub, EditMenu_FindDown
	return

DevMenu_DevMap:
	My_ToolsCall(hEdit,"P:\MyPrograms\EDITORS\Blumind\Blumind.exe",A_ScriptDir . "\Main.bmd")
	return

DevMenu_Hide:
	Menu, MyMenuBar, Delete,&Dev
	Menu, ViewMenu, ToggleCheck, &DevMenu
	Return

DevEdit_Code:
	My_OpenFile(hEdit,  A_ScriptDir . "\APEdit.ahk")
	return

DevEdit_Menus:
	My_OpenFile(hEdit, A_ScriptDir . "\APEdit.ahk")
	return

DevEdit_Keys:
	My_OpenFile(hEdit, A_ScriptDir . "\APEdit.ahk")
	return

DevEdit_Keywords:
	; This will fail if we have chosen another keyword file
	My_OpenFile(hEdit,A_ScriptDir . "\hes\KeyWords.hes")
	return

DevEdit_FormsAHK:
	My_OpenFile(hEdit, A_ScriptDir . "\inc\_Forms.ahk")
	return

DevEdit_HiEditAHK:
	My_OpenFile(hEdit, A_ScriptDir . "\inc\HiEdit.ahk")
	return

DevEdit_HiEditINC:
	My_OpenFile(hEdit,A_ScriptDir . "\inc\HiEdit.inc")
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

My_GetLineNumber:
	;Get the line number
	MyLineNumber := HE_LineFromChar(hEdit, HE_LineIndex(hEdit))
	MyLineNumber++ ; Line index is zero based!!!
	;Get the File Name
	; The tab index changes if you add more tabs
	; So use file name, but the variable MyFileName contains a dot, an illegal character for a variable name!
	MyFile := RegExReplace(MyFileName, "\." , "_")
	;Setup for Array Separator
	MySep =  `n
	return

My_GotoLine(hEdit, line){
	line_idx := HE_LineIndex(hEdit, line-1)
	HE_SetSel(hEdit, line_idx, line_idx)
	HE_ScrollCaret(hEdit )
;	HE_Scroll(hEdit,1,-1)
	return
}

My_GotoNav(NavPath) {
	Global hEdit
	StringSplit, Nav, NavPath , @

	; Check if this is current file
	If (HE_GetFileName(hEdit, idx=-1) = Nav1) {
		My_GotoLine(hEdit, Nav2)
		return
	}

	; Check through all open files
	count := HE_GetFileCount(hEdit)
	Loop, %count%
	{
		If (HE_GetFileName(hEdit, A_Index) = Nav1) {
			HE_SetCurrentFile(hEdit, A_Index)
			My_GotoLine(hEdit, Nav2)
			; *** My_GotoNav some how the active index is not being set to the new tab
			return
		}
	}

	; Else open file
	If (FileExist(Nav1) and InStr(FileExist(Nav1), "D")=0 ){
		My_OpenFile(hEdit, Nav1)
		My_GotoLine(hEdit, Nav2)
	} Else {
		msgbox, % "Can't open " NavPath
	}
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
	; *** My_GetBlock - this fails on the last line of the file!
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

My_ParseBundle(hEdit,BundleFile) {
	; This function attempts to copy the "Variables" "Tab Stops" "Placeholders" and "Mirrors" functionality of TextMate

	; Load global variables - Naughty but it works!
	Global MyFilePath
	Global FindText

	;Load the bundle text
	IfNotExist, %BundleFile%
	{
		Msgbox, ,%BundleFile%, Can't find the bundle file
		return
	}

	FileRead, BundleText, %BundleFile%

	; Replace $GetSelectedText
	If (InStr(BundleText, $GetSelectedText))
	{
		ReplaceText := HE_GetSelText(hEdit)
		StringReplace , BundleText, BundleText, $GetSelectedText , %ReplaceText% , All
	}

	; Replace $0 to stop it triggering the loop
	If (InStr(BundleText, $0))
	{
		StringReplace , BundleText, BundleText, $0 , -InsertHere-
	}

	;Check for $ variables
	$Position := RegExMatch(BundleText, "P)\$\{\d*:.*?\}|\$\w*|\$\d*|\{\$\d*\}", $Length)
	While  $Position {

		; Find the variable
		$Text := substr(BundleText,$Position,$Length)

		; Extract any default values
		IfInString, $Text, :
		{
			$Default := 	SubStr($Text, InStr($Text, ":" )+1 , -1)
		}

		; Display GUI with current version of BundleText
		InputBox, ReplaceText , Process Bundle - %$Text% , %BundleText% , , , , , , , , %$Default%
		If ErrorLevel
		{
			return
		}

		; If the suggested filename does not exist then ask
		If ($Text = "$GetFileName" or $Text =  "$GetRelFileName") {
			IfNotExist, %ReplaceText%
			{
				FileSelectFile, ReplaceText, 3, %MyFilePath%, Get file name for %$Text%
				If ErrorLevel
				{
					return
				}
			}

			; Make a full path
			Loop, %ReplaceText%
			{
				ReplaceText = %A_LoopFileLongPath%
			}

			; Make relative if required
			If ($Text = "$GetRelFileName") {
				; Make relative path
				ReplaceText := My_GetRelPath(HE_GetFileName(hEdit),ReplaceText)
			}
		}

		; Replace the variable
		StringReplace , BundleText, BundleText, %$Text%, %ReplaceText%

		; Look for and replace mirrors
		If (RegExMatch($Text, "\d+", $Count)){
			StringReplace , BundleText, BundleText, {$%$Count%}, %ReplaceText% , All
		}

		; Repeat search
		$Position := RegExMatch(BundleText, "P)\$\{\d*:.*?\}|\$\w*|\$\d*|\{\$\d*\}", $Length)
	}

	If (RegExMatch(BundleText, "\$[a-z]")) {
		Msgbox, More to do
		; goto Iterate
	}

	;Save insertion point
	$Insert := HE_LineIndex(hedit,-1)-1

	;Write bundle
	My_SendText(hEdit,BundleText)

	; Check for insertion point
	If (InStr(BundleText, "-InsertHere-"))
	{
; 		$Offset := InStr(BundleText, "-InsertHere-")
; 		HE_SetSel(hEdit,$Insert+$Offset,$Insert+$Offset)
		FindText := 	"-InsertHere-"
		GoSub, EditMenu_FindTUp
	}
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
	; *** My_ToolsCall - this fails if param file name has spaces!
	IfExist, %fnTool%
	{
		Run, %fnTool% %A_Space% "%param%",""
	}
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

;==================Callback Functions===================
; *** Monitor File for Changes - how?



; *** OnHiEdit - how to use?
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
#include inc\HIEdit.ahk
#include inc\Attach.ahk
#include inc\Dlg.ahk
#include inc\COM.ahk

; Print by Jballi
#include inc\HiEdit_Print.ahk

; Macros
#include mac\default.ahk

; Plugins
#include plg\default.ahk

