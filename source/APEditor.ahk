; A Programmable Editor Gavin M Holt
; Standing upon the shoulders of giants, developed borrowing from various scripts:
; -	HiEdit.dll				Antonis Kyprianou (akyprian)
; -	HiEdit.ahk				Miodrag Milic (majkinetor, miodrag.milic@gmail.com)
; -	HiEdit _test.ahk 		magnetometer
; -	AHKPAd					Michael Peters
; -	QuickAHK  				jballi
; -	Vic Editor				Normand Lamoureux
; - Adventure IDE   		alguimist
;
; I have tried to avoid operations that process the whole file - preferring to process a line at a time,
; exceptions include:
; -	Block:					If you "select all" the whole file is in memory
; -	FileMenu_OpenTemplate:	Read whole file in then inserts
; -	EditMenu_FindREDown:	Reads the rest of the file before each search
; -	InsertMenu_File:		Reads whole file in then inserts
;
; Variables in functions are local - any name you like
;
; Variables in subroutines: are global
; - v for locals  
; - g for intended globals
; - clear before return

; Setup AHK Environment
; A_ScriptDir is the location of the compiled executable
#SingleInstance on
#NoEnv
#NoTrayIcon
#MaxMem 128
SetWorkingDir,%A_ScriptDir%
AutoTrim,Off
SetBatchLines,-1
SetControlDelay,-1
SetWinDelay,-1
ListLines,Off
DetectHiddenWindows,On
SetTitleMatchMode,2
SendMode,Input
Process,Priority,,A
CoordMode,Mouse,Relative

; Single Instance
; I can't get this to work
; Therefore all launches are via APRunner.exe
; Re-launching APEditor.exe will kill any other running instance - with data loss.

; GUI SETUP
Gui, +LastFound +Resize
gHWND := WinExist()			; Don't move this above the first Gui command
Gui, font, s12, Consolas    ; This does not seem to work with the menu fonts

; Toolbar with static pictures, and no tooltips, for speed!
; calling by-passes MyGoSub() so each needs to Gosub, DoGetFilePath
Gui, Margin,0,0
Gui, Add, Picture, HWNDToolBack x0 y0 w965 h44 BackgroundTrans,img/bluegrad.bmp
Gui, Add, Picture, gFileMenu_New x10 y6 BackgroundTrans, img/newbutton.png
Gui, Add, Picture, gFileMenu_Open x50 y6 BackgroundTrans, img/openbutton.png
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

Gui, Add, Picture, gToolsMenu_$hell x630 y7 BackgroundTrans, img/shellbutton.png
Gui, Add, Picture, gProjectMenu_Run x670 y6 w36 h36  BackgroundTrans, img/runbutton.png
Gui, Add, Picture, x710 y6 BackgroundTrans, img/sep.bmp

Gui, Add, Picture, gFileMenu_Close x720 y7 BackgroundTrans, img/closebutton.png
Gui, Add, Picture, gDoEgg x760 y6 BackgroundTrans, img/sep.bmp

; Menus
; Load menu before display for speed?
MyMenuCreate()

; Default menu settings
Menu, FileMenu, Check, &Monitor
Menu, OptionsMenu, Check, Line &Numbers
Menu, OptionsMenu, Check, &Auto Indent
Menu, OptionsMenu, Check, &Light

; Display menu
Gui, Menu, MyMenuBar

; Statusbar
; No thanks

; HiEdit
HiEdit1 := HE_Add(gHWND,0,44,965,636, "HSCROLL VSCROLL HILIGHT TABBEDBOTTOM FILECHANGEALERT")
gStyle := "s18"
gFont  := "Consolas"
gTAB   := 4
HE_SetFont(HiEdit1, gStyle "," gFont)
HE_SetTabWidth(HiEdit1,gTAB)
HE_AutoIndent(HiEdit1, true), gAutoIndent := true
HE_LineNumbersBar(HiEdit1, "automaxsize"), gLineNumbers := true

; TodogColors
Gosub, OptionsMenu_Light
HE_SetColors(HiEdit1, colours)
HE_SetKeywordFile("APEditor.hes")

; Show the whole application
Attach(HiEdit1, "w h")
Attach(ToolBack, "w")
Gui, Show, w965 h680, APEditor
Gui, Maximize

; Timers
SetTimer, DoSetTitle, 50

; Load command line parameters
gParameters = %1%
If gParameters
{
    MyOpenFile(HiEdit1, gParameters)
    ControlFocus, HiEdit1
    ; Clear variables
    gParameters :=
} else {
    ; Set focus on *File1 for typing!
    ControlFocus, HiEdit1
}

; End of Autoexec Section: Defined by return/exit/hotkeys
return

; Hotkeys
#IfWinActive ahk_class AutoHotkeyGUI

    ; ^Enter::	Adds line below - see HiEditor defaults
    +Enter::	MyGoSub("InsertMenu_LineBelow")
    !Enter::	MyGoSub("InsertMenu_Stamp")
    !SC02B::	MyGoSub("ToolsMenu_Explorer")

    ^A::	    MyGoSub("SelectMenu_All")
    ^B::	    Send {Home}
;	^C::	    COPY
    ^D::	    MyGoSub("BlockMenu_Duplicate")
    ^E::	    Send {End}
    ^F::	    MyGoSub("EditMenu_Find")
    ^G::	    MyGoSub("EditMenu_GoTo")
    ^H::	    MyGoSub("EditMenu_Replace")
    ^I::        MyGoSub("InsertMenu_File")
    ^J::	    MyGoSub("")
    ^K::	    MyGoSub("EditMenu_DelEOL")
    ^L::	    MyGoSub("SelectMenu_LineDown")
    ^M::	    MyGoSub("EditMenu_BookMark")
    ^N::	    MyGoSub("FileMenu_New")
    ^O::	    MyGoSub("FileMenu_Open")
    ^P::	    MyGoSub("FileMenu_Print")
;   ^Q::	    MyGoSub("BlockMenu_Comment")
    ^R::	    MyGoSub("FileMenu_Revert")
    ^S::	    MyGoSub("FileMenu_Save")
    ^T::	    MyGoSub("")
    ^U::	    MyGoSub("EditMenu_UnMark")
;	^V::	    PASTE
    ^W::	    MyGoSub("FileMenu_Close")
;	^X::	    CUT
    ^Y::	    MyGoSub("BlockMenu_Yank")
;	^Z::	    UNDO

     ^+.::	    MyGoSub("BlockMenu_Indent")
     ^+,::	    MyGoSub("BlockMenu_Outdent")
    ^space::	MyGoSub("SelectMenu_Word")
    ^8::		MyGoSub("SelectMenu_Word") MyGoSub("EditMenu_Find")
    ^=::		MyGoSub("ToolsMenu_Calculate")
    ^SC027::	MyGoSub("PreMenu_1LineComment") ; ^;
    ^SC02B::	MyGoSub("PreMenu_2LineComment") ; ^#
    ^/::		MyGoSub("PreMenu_3LineComment") ; ^/
    ^-::		MyGoSub("PreMenu_4LineComment") ; ^-
    ^;::		MyGoSub("PreMenu_5LineComment") ; ^;
    ^Q::    	MyGoSub("PreMenu_ClearPrefix")

;	^+A::	    All occurances for multi cursor editor
    ^+B::	    Send +{Home}
    ^+C::	    MyGoSub("EditMenu_CopyAppend")
    ^+D::	    MyGoSub("")
    ^+E::	    Send +{End}
    ^+F::	    MyGoSub("EditMenu_FindRE")
    ^+G::	    MyGoSub("EditMenu_Grep")
    ^+H::	    MyGoSub("EditMenu_ReplaceAll")
    ^+I::	    MyGoSub("")
    ^+J::	    MyGoSub("")
    ^+K::	    MyGoSub("EditMenu_DelBOL")
    ^+L::	    MyGoSub("SelectMenu_LineUp")
    ^+N::	    MyGoSub("OptionsMenu_LineNumbers")
    ^+M::	    MyGoSub("")
    ^+O::       MyGoSub("FileMenu_OpenSelected")
    ^+P::	    MyGoSub("")
    ^+Q::       MyGoSub("")
    ^+R::	    MyGoSub("")
    ^+S::	    MyGoSub("FileMenu_SaveAs")
    ^+T::	    MyGoSub("")
    ^+U::	    MyGoSub("")
    ^+V::	    MyGoSub("EditMenu_PastePlainText")
    ^+W::	    MyGoSub("")
    ^+X::	    MyGoSub("EditMenu_CutAppend")
    ^+Y::       MyGoSub("")
    ^+Z::	    MyGoSub("EditMenu_Redo")

    ^!A::	    MyGoSub("")
    ^!B::	    MyGoSub("ProjectMenu_Backup")
    ^!C::	    MyGoSub("")
    ^!D::	    MyGoSub("ToolsMenu_Diff")
    ^!E::	    MyGoSub("DoEgg")
    ^!F:: 	    MyGoSub("EditMenu_FindinFiles")
    ^!G::	    MyGoSub("")
    ^!H::	    MyGoSub("EditMenu_Replaceinfiles")
    ^!I::	    MyGoSub("InsertMenu_File")
    ^!J::	    MyGoSub("ProjectMenu_JobsToDo")
    ^!K::	    MyGoSub("")
    ^!L::	    MyGoSub("")
    ^!M::	    MyGoSub("ProjectMenu_MakeIt")
    ^!N::	    MyGoSub("")
    ^!O::	    MyGoSub("")
    ^!P::	    MyGoSub("")
    ^!Q::	    MyGoSub("")
    ^!R::	    MyGoSub("ProjectMenu_Run")
    ^!S::	    MyGoSub("")
    ^!T::	    MyGoSub("FileMenu_OpenTemplate")
    ^!U::	    MyGoSub("")
    ^!V::	    MyGoSub("FileMenu_ViewBackup")
    ^!W::	    MyGoSub("")
    ^!X::	    MyGoSub("")
    ^!Y::       MyGoSub("")
    ^!Z::       MyGoSub("")
    ^!SC02B::	MyGoSub("ToolsMenu_$hell")

;  !A
;  !C
;  !D
    !G::        MyGoSub("AltMenu_Goto")
    !I::		MyGoSub("AltMenu_File")
;  !J
;  !K
    !L::        MyGoSub("AltMenu_InsertLine")
;  !M
;  !N
    !O::		MyGoSub("AltMenu_Open")
;  !P
;  !Q
    !R::        MyGoSub("HelpMenu_Reload")
    !S::		MyGoSub("AltMenu_Snippet")
    !T::        MyGoSub("AltMenu_OpenTemplate")
;  !U
;  !V
    !W::        MyGoSub("WindowsMenu_FileList")
;  !X
;  !Y
;  !Z

    +!F::       MyGoSub("AltMenu_FindinFiles")
    +!L::       MyGoSub("AltMenu_EditLine")
    +!T::		MyGoSub("AltMenu_EditTemplate")
    +!S::		MyGoSub("AltMenu_EditSnippet")

    ^F1::	    MyGoSub("")
    ^F2::	    MyGoSub("EditMenu_BookMark")
    F5::	    MyGoSub("")
    ^F7::	    MyGoSub("ToolsMenu_SpellCheck")
    F9::	    MyGoSub("")
    F10::	    MyGoSub("")
    F11::	    MyGoSub("")

;	^Right::	Word Right
;	^Left::		Word Left

    ^TAB::	    MyGoSub("WindowsMenu_NextTab")
    ^+TAB::	    MyGoSub("WindowsMenu_PrevTAB")

;	Up::		Up
;	Down::		Down

;   +Up::		Select up
;   +Down::		Select down

    ^Up::		MyGoSub("EditMenu_FindUp")
    ^Down::		MyGoSub("EditMenu_FindDown")

    ^+Up::		MyGoSub("BlockMenu_ShiftUp")
    ^+Down::	MyGoSub("BlockMenu_ShiftDown")

    !Left::		MyGoSub("EditMenu_GoBack")
    !Right::	MyGoSub("EditMenu_GoForward")

    +!Up::      MyGoSub("")
    +!Down::    MyGoSub("")

;	^DEL::		; 	Delete to next word
;	+DEL::		; 	BACKSPACE if not selection, ^X if there is a selection
;	^+DEL::	    ; 	Delete block

    ^BS::       Send +^{Left}{BS}

    ^WheelUp::   MyGoSub("FontInc")
    ^WheelDown:: MyGoSub("FontDec")

#IfWinActive Open a file
    TAB::		Send {Down}

#IfWinActive Insert file
    TAB::		Send {Down}

#IfWinActive Open a template
    TAB::		Send {Down}

#IfWinActive Save file as
    TAB::		Send {Down}

#IfWinActive

; HiEdit Naviagtion Keys
; -	+{Right} 	Extend a selection one character to the right. SHIFT+RIGHT ARROW
; -	+{Left} 	Extend a selection one character to the left. SHIFT+LEFT ARROW
; -	+^{Right}	Extend a selection to the end of a word. CTRL+SHIFT+RIGHT ARROW NB To the next word including W
; -	+^{Left}	Extend a selection to the beginning of a word. CTRL+SHIFT+LEFT ARROW
; -	+{End}		Extend a selection to the end of a line. SHIFT+END
; -	+{Home}	    Extend a selection to the beginning of a line. SHIFT+HOME
; -	+{Down}     Extend a selection one line down. SHIFT+DOWN ARROW
; -	+{up}       Extend a selection one line up. SHIFT+UP ARROW
; -	+{PgDn}	    Extend a selection one screen down. SHIFT+PAGE DOWN
; -	+{PgUp}	    Extend a selection one screen up. SHIFT+PAGE UP
; -	+^{Home}	Extend a selection to the beginning of a document. CTRL+SHIFT+HOME
; -	+^{End}	    Extend a selection to the end of a document. CTRL+SHIFT+END
; -	^A			Extend a selection to include the entire document. CTRL+A
; -	^Enter		Adds a line below the cursor

; Windows Keys
; - Avoid windows keys

; Menu Definitons
MyMenuCreate(){

    Menu, FileMenu, Add, &New	Ctrl+N,DoMenuHandler
    Menu, FileMenu, Add, &Open...	Ctrl+O,DoMenuHandler
    Menu, FileMenu, Add, Rever&t	Ctrl+R,DoMenuHandler
    Menu, FileMenu, Add, &Close	Ctrl+W,DoMenuHandler
    Menu, FileMenu, Add,
    Menu, FileMenu, Add, Open Se&lected	Ctrl+Shift+O,DoMenuHandler
    Menu, FileMenu, Add, Open &Template...	Ctrl+Alt+T,DoMenuHandler
    Menu, FileMenu, Add,
    Menu, FileMenu, Add, &Save	Ctrl+S,DoMenuHandler
    Menu, FileMenu, Add, Save &As...	Ctrl+Shift+S,DoMenuHandler
    Menu, FileMenu, Add, Save A&ll,DoMenuHandler
    Menu, FileMenu, Add,
    Menu, FileMenu, Add, Save &Backup...	Ctrl+Alt+B,DoMenuHandler
    Menu, FileMenu, Add, &View Backup...	Ctrl+Alt+V,DoMenuHandler
    Menu, FileMenu, Add,
    Menu, FileMenu, Add, &Monitor,DoMenuHandler
    Menu, FileMenu, Add,
    Menu, FileMenu, Add, Print...	Ctrl+P,DoMenuHandler
    Menu, FileMenu, Add,
    Menu, FileMenu, Add, E&xit,	DoMenuHandler

    Menu, InsertMenu, Add, Line &Above	Ctrl+Enter,DoMenuHandler
    Menu, InsertMenu, Add, Line &Below	Shift+Enter,DoMenuHandler
    Menu, InsertMenu, Add,
    Menu, InsertMenu, Add, &File...	Ctrl+I,DoMenuHandler
    Menu, InsertMenu, Add, File &Name,DoMenuHandler
    Menu, InsertMenu, Add, &Get FileName..,DoMenuHandler
    Menu, InsertMenu, Add, &Rel FileName..,DoMenuHandler
    Menu, InsertMenu, Add,
    Menu, InsertMenu, Add, &Date,DoMenuHandler
    Menu, InsertMenu, Add, &Time,DoMenuHandler
    Menu, InsertMenu, Add, &Stamp	Alt+Enter,DoMenuHandler

    Menu, SelectMenu, Add, &All	Ctrl+A,DoMenuHandler
    Menu, SelectMenu, Add, Line&Down	Ctrl+L,DoMenuHandler
    Menu, SelectMenu, Add, Line&Up	Ctrl+Shift+L,DoMenuHandler
    Menu, SelectMenu, Add, &BOL	Ctrl+Shift+B,DoMenuHandler
    Menu, SelectMenu, Add, &EOL	Ctrl+Shift+E,DoMenuHandler

    Menu, FormatMenu, Add, &Upper Case,DoMenuHandler
    Menu, FormatMenu, Add, &Lower Case,DoMenuHandler
    Menu, FormatMenu, Add, &Reverse Case,DoMenuHandler
    Menu, FormatMenu, Add, &Proper Case,DoMenuHandler

    Menu, EditMenu, Add, &Undo	Ctrl+Z,DoMenuHandler
    Menu, EditMenu, Add, R&edo	Ctrl+Shift+Z,DoMenuHandler
    Menu, EditMenu, Add,
; 	Menu, EditMenu, Add, &Cut	Ctrl+X,DoMenuHandler
; 	Menu, EditMenu, Add, C&opy	Ctrl+C,DoMenuHandler
; 	Menu, EditMenu, Add, &Paste	Ctrl+V,DoMenuHandler
; 	Menu, EditMenu, Add,
    Menu, EditMenu, Add, Cut &Append	Ctrl+Shift+X,DoMenuHandler
    Menu, EditMenu, Add, Copy Appen&d	Ctrl+Shift+C,DoMenuHandler
    Menu, EditMenu, Add, Paste Plain &Text	Ctrl+Shift+V,DoMenuHandler
    Menu, EditMenu, Add,
    Menu, EditMenu, Add, &Select,		:SelectMenu
    Menu, EditMenu, Add, C&hange Case,	:FormatMenu
    Menu, EditMenu, Add, &Insert,		:InsertMenu
    Menu, EditMenu, Add,
    Menu, EditMenu, Add, &Goto...	Ctrl+G,DoMenuHandler
    Menu, EditMenu, Add, Grep...	Ctrl+Shift+G,DoMenuHandler
    Menu, EditMenu, Add,
    Menu, EditMenu, Add, Book &Mark	Ctrl+F2,DoMenuHandler
; 	Menu, EditMenu, Add, U&nMark	Ctrl+U,DoMenuHandler
    Menu, EditMenu, Add, Go &Back	Alt+Left,DoMenuHandler
    Menu, EditMenu, Add, Go &Forwards	Alt+Right,DoMenuHandler
    Menu, EditMenu, Add,
    Menu, EditMenu, Add, &Find...	Ctrl+F,DoMenuHandler
    Menu, EditMenu, Add, FindR&E...	Ctrl+Shift+F,DoMenuHandler
    Menu, EditMenu, Add, Find in Files...	Ctrl+Alt+F,DoMenuHandler
    Menu, EditMenu, Add,
    Menu, EditMenu, Add, Find Up	Ctrl+Up,DoMenuHandler
    Menu, EditMenu, Add, Find Down	Ctrl+Down,DoMenuHandler
    Menu, EditMenu, Add,
    Menu, EditMenu, Add, &Replace...	Ctrl+H,DoMenuHandler
    Menu, EditMenu, Add, Replace A&ll...	Ctrl+Shift+H,DoMenuHandler
    Menu, EditMenu, Add, Replace in Files...	Ctrl+Alt+H,DoMenuHandler

    ; Submenus for Block, must be defined first!

    Menu, TrimMenu, Add, &RTrim,DoMenuHandler
    Menu, TrimMenu, Add, &LTrim,DoMenuHandler
    Menu, TrimMenu, Add, &FullTrim,DoMenuHandler
    Menu, TrimMenu, Add, &EmptyLines,DoMenuHandler

    Menu, SortMenu, Add, &Ascending,DoMenuHandler
    Menu, SortMenu, Add, &Descending,DoMenuHandler
    Menu, SortMenu, Add, &Integer,DoMenuHandler
    Menu, SortMenu, Add
    Menu, SortMenu, Add, &Remove Dups,DoMenuHandler

    Menu, PreMenu, Add, &Bullet,DoMenuHandler
    Menu, PreMenu, Add, &Number,DoMenuHandler
    Menu, PreMenu, Add, &Renumber,DoMenuHandler
    Menu, PreMenu, Add
    Menu, PreMenu, Add, 1 `; Line Comment	Ctrl+`;,DoMenuHandler
    Menu, PreMenu, Add, 2 # Line Comment	Ctrl+#,DoMenuHandler
    Menu, PreMenu, Add, 3 // Line Comment	Ctrl+/,DoMenuHandler
    Menu, PreMenu, Add, 4 -- Line Comment	Ctrl+-,DoMenuHandler
    Menu, PreMenu, Add
    Menu, PreMenu, Add,  &Clear Prefix	Ctrl+Q,DoMenuHandler

    Menu, BlockMenu, Add, &Indent	TAB,DoMenuHandler
    Menu, BlockMenu, Add, &Outdent	+TAB,DoMenuHandler
    Menu, BlockMenu, Add
    Menu, BlockMenu, Add, &Duplicate	Ctrl+D,DoMenuHandler
    Menu, BlockMenu, Add, &Yank	Ctrl+Y,DoMenuHandler
    Menu, BlockMenu, Add
    Menu, BlockMenu, Add, Shift &Up	Ctrl+Up,DoMenuHandler
    Menu, BlockMenu, Add, Shift &Down	Ctrl+Down,DoMenuHandler
    Menu, BlockMenu, Add
    Menu, BlockMenu, Add, &Prefix,		:PreMenu
    Menu, BlockMenu, Add, &Sort, 		:SortMenu
    Menu, BlockMenu, Add, &Trim, 		:TrimMenu

    ; Submenus for Scripts, must be defined first!

    Menu, ProjectMenu, Add, &Run	Ctrl+Alt+R,DoMenuHandler
    Menu, ProjectMenu, Add, &Makeit	Ctrl+Alt+M,DoMenuHandler
    Menu, ProjectMenu, Add, &Jobs ToDo	Ctrl+Alt+J,DoMenuHandler
    Menu, ProjectMenu, Add
    Menu, ProjectMenu, Add, &Backup	Ctrl+Alt+B,DoMenuHandler
    Menu, ProjectMenu, Add, &Versions	Ctrl+Alt+V,DoMenuHandler

    Menu, ToolsMenu, Add, &SpellCheck	Ctrl+F7,DoMenuHandler
    Menu, ToolsMenu, Add, &Calculate	Ctrl+=,DoMenuHandler
    Menu, ToolsMenu, Add, &Diff   	Ctrl+Alt+D,DoMenuHandler
    Menu, ToolsMenu, Add, &$hell	Ctrl+Alt+#,DoMenuHandler

    ;  :)
    Menu, AltMenu, Add, &Open File	Alt+O,DoMenuHandler
    Menu, AltMenu, Add, Open &Backup	Alt+B,DoMenuHandler
    Menu, AltMenu, Add, Insert &Template	Alt+T,DoMenuHandler
    Menu, AltMenu, Add, Insert &Snippet	Alt+S,DoMenuHandler
    Menu, AltMenu, Add, Insert &Line	Alt+L,DoMenuHandler
    Menu, AltMenu, Add, &Goto	Alt+G,DoMenuHandler
    Menu, AltMenu, Add, &Windows	Alt+W,DoMenuHandler

    Menu, ScriptsMenu, Add, &Tools,         :ToolsMenu
    Menu, ScriptsMenu, Add, &Project,       :ProjectMenu

    ; Submenus for Options, must be defined first!

    Menu, EOLMenu,Add, Win CRLF,DoMenuHandler
    Menu, EOLMenu,Add, Unix LF,DoMenuHandler
    Menu, EOLMenu,Add, Mac CR,DoMenuHandler

    Menu, OptionsMenu, Add, &Font,DoMenuHandler
    Menu, OptionsMenu, Add, Syta&x Colours,DoMenuHandler
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, &Tabs,DoMenuHandler
    Menu, OptionsMenu, Add, Convert &EOL,	:EOLMenu
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, &Light,DoMenuHandler
    Menu, OptionsMenu, Add, &Dark,DoMenuHandler
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, Line &Numbers,DoMenuHandler
    Menu, OptionsMenu, Add, &Auto Indent,DoMenuHandler
    Menu, OptionsMenu, Add
    Menu, OptionsMenu, Add, F&ull Screen,DoMenuHandler

    Menu, WindowsMenu, Add, Next Tab	Ctrl+TAB,DoMenuHandler
    Menu, WindowsMenu, Add, Prev Tab	Ctrl+Shift+TAB,DoMenuHandler
    Menu, WindowsMenu, Add, &File List	Alt+W,DoMenuHandler

    Menu, HelpMenu, Add, &ToDo,DoMenuHandler
    Menu, HelpMenu, Add
    Menu, HelpMenu, Add, &Contents,DoMenuHandler
    Menu, HelpMenu, Add, &Menus,DoMenuHandler
    Menu, HelpMenu, Add, &Keys,DoMenuHandler
    Menu, HelpMenu, Add
    Menu, HelpMenu, Add, &Source,DoMenuHandler
    Menu, HelpMenu, Add
    Menu, HelpMenu, Add, &About,DoMenuHandler

    Menu, MyMenuBar, Add,&File,			:FileMenu
    Menu, MyMenuBar, Add,&Edit,			:EditMenu
    Menu, MyMenuBar, Add,&Block,		:BlockMenu
    Menu, MyMenuBar, Add,&Scripts,		:ScriptsMenu
    Menu, MyMenuBar, Add,&Options,		:OptionsMenu
    Menu, MyMenuBar, Add,&Windows,	    :WindowsMenu
    Menu, MyMenuBar, Add,&Help,		    :HelpMenu
    Menu, MyMenuBar, Color,  FFFFFFFF
}

; Functions
; Name My* so I know where they came from

MyGoSub(Label){
    If IsLabel(Label)
    {
        Gosub, DoGetFilePath 	; Refresh file related globals
        Gosub, %Label%      	; Execute subroutine
    } else {
        msgbox, Label "%Label%" or HotKey does not exist
    }
}

DoSetTitle(HiEdit1,gHWND){
    if HE_GetModify(HiEdit1, idx=-1) {
        pre := "*"
        }
    fn := HE_GetFileName(HiEdit1,-1)
    WinSetTitle,ahk_id %gHWND%,,%pre%%fn% - APEditor
    return
}

MyOpenFile(HiEdit1,fn) {
    HE_OpenFile(HiEdit1,fn)
    If (ErrorLevel = 0) {
        MsgBox,48,"Error in MyOpenFile","Unable to open the file"
        return
    } else {
        DoSetTitle(HiEdit1,gHWND)
        ControlFocus, ahk_id %gHWND%

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
            MyGotoLine(HiEdit1,Found2)
        } else {
            ; Record history
            FileAppend , %fn%@1`n , %A_ScriptDir%\APEditor.his
        }
    }
}

MyGotoLine(HiEdit1, line) {
    line_idx := HE_LineIndex(HiEdit1, line-1)
    HE_SetSel(HiEdit1, line_idx, line_idx)
    HE_ScrollCaret(HiEdit1)
    return
}

MyReplaceLine(HiEdit1,line,text){
    line_idx := HE_LineIndex(HiEdit1, line)
    HE_SetSel( HiEdit1, line_idx, line_idx+HE_LineLength(HiEdit1, line_idx))
    HE_ReplaceSel(HiEdit1, text)
}

MyIsRE(FindText){
    ; Test if the FindText is a RE or not - can't be done as a regular find string may have dots
    If (RegExMatch(FindText, FindText)) {
        Return 0
    } else {
        Return 1
    }
}

MyGetAllText(HiEdit1){
    MyGoSub("SelectMenu_All")
    Return HE_GetSelText(HiEdit1)
}

MySendText(HiEdit1,Text){
    ; First option - via the keyboard hook - slow and adds extra CTLF
    ; SendInput, {raw} %Text%
    ; Second option - message to hiEdit control directly
    SendMessage,0xC2,,&Text,,ahk_id %HiEdit1%
}

MyGetRelPath(CurrentFn,InsertFn){
    If (FileExist(CurrentFn)){
        Loop, %CurrentFn%
        {
            CurrentP := A_LoopFileDir
            Loop, %InsertFn%
            {
                InsertP := A_LoopFileDir
                If (CurrentP = InsertP){
                    ; Same directory
                    ReplaceText := A_LoopFileName
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
                    } else {
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
    } else {
        msgbox, Can't make relative path to unnamed file!
        ReplaceText := InsertFn
    }
    Return %ReplaceText%
}

MyToolsCall(HiEdit1,fnTool,param){
; ToDo MyToolsCall - this fails if filenames have spaces!
    Run, %fnTool% %A_Space% "%param%", ""
}

MyComspecCall(HiEdit1,fnTool,param,output,gFilePath){
    IfExist, %fnTool%
    {
        Runwait, %ComSpec% /c %fnTool% %A_Space%  %param% > %output% , %gFilePath% , Hide
    }
}

MyHesDel(COL){
    COL := SubStr(COL,3,6)
    COL := "0x01"COL
    return COL
}

MyHesCol(COL){
    COL := SubStr(COL,3,6)
    COL := "0x00"COL
    return COL
}

; Callback Functions
; How to use?
OnHiEdit(Hwnd, Event, Info)
{
    OutputDebug % Hwnd " | " Event  " | " Info
    ; Works with O:\MyProfile\cmd\Dbgview.exe
}

; Subroutines
; v variables should be cleared or they will persist
; g variable are intended to be global

DoMenuHandler:
    ; Uses the name of the menu and item to call a subroutine,
    ; after clearing out unwanted menu formatting
    vMenuLabel := A_ThisMenu . "_" . A_ThisMenuItem
    StringSplit, vMenuLabel,vMenuLabel, %A_Tab%
    vMenuLabel := vMenuLabel1
    vMenuLabel := RegExReplace(vMenuLabel, "&" , "")
    vMenuLabel := RegExReplace(vMenuLabel, ";" , "")
    vMenuLabel := RegExReplace(vMenuLabel, "#" , "")
    vMenuLabel := RegExReplace(vMenuLabel, " " , "")
    vMenuLabel := RegExReplace(vMenuLabel, "\." , "")
    vMenuLabel := RegExReplace(vMenuLabel, "/" , "")
    vMenuLabel := RegExReplace(vMenuLabel, "-" , "")
    Gosub, DoGetFilePath
    Gosub, %vMenuLabel%

    ; Clear variables
    vMenuLabel :=
    return

DoGetFilePath:
    ;Designed to set global variables
    vFN := HE_GetFileName(HiEdit1,-1)
    If (FileExist(vFN)) {
        Loop, %vFN%
        {
            gFilePath   := A_LoopFileDir
            gFileName   := A_LoopFileName
            gFileExt    := A_LoopFileExt
            ; FullPath  := gFilePath . "\" . gFileName
        }
    } else {
            gFilePath   :=
            gFileName   :=
            gFileExt    :=
    }

    ; Clear variables
    vFN :=
    return

DoSetTitle: ; SetTimer won't call a function!
    DoSetTitle(HiEdit1,gHWND)
    return

DoGetBlock:
; ToDo - this fails on the last line of the file!
    ;Get start and end positions
    HE_GetSel(HiEdit1,BlockStart,BlockEnd)
    ;Collect each line
    MySep = `r`n
    BlockStartLindx := HE_LineFromChar(HiEdit1,BlockStart)
    BlockEndLindx:= HE_LineFromChar(HiEdit1,BlockEnd)
    BlockCounter := BlockStartLindx
    ;First Line
    Block := HE_GetLine(HiEdit1,BlockCounter)
    BlockCounter++
    ; Loop through the rest -
    While (BlockCounter <= BlockEndLindx ) {
        Block := Block MySep HE_GetLine(HiEdit1,BlockCounter)
        BlockCounter++
    }
    ; Add terminal EOL
    ;Block := Block MySep

    ; Set Selection - for later replacement
     HE_SetSel(HiEdit1,HE_LineIndex(HiEdit1, BlockStartLindx) , HE_LineIndex(HiEdit1, BlockEndLindx) + HE_LineLength(HiEdit1,BlockEndLindx))

    ; Set cursor for Select line up

    ; Clear variables

    return

DoSendBlock:
    ; Send the text
    HE_ReplaceSel(HiEdit1, Block)
    ; Reselect the new block - may be a different length to the old block!
    HE_SetSel(HiEdit1,HE_GetSel(HiEdit1)-StrLen(Block),HE_GetSel(HiEdit1))
    return

DoEgg:
    MsgBox,48,Easter DoEgg, OK - now I have DoEgg on my face!
    return

FileMenu_New:
    HE_NewFile(HiEdit1)
    return

FileMenu_OpenSelected:
    ; If a filename in the text is selected open it!
    vSel := HE_GetSelText(HiEdit1)
    If (FileExist(vSel) and InStr(FileExist(vSel), "D")=0 ){
        MyOpenFile(HiEdit1, vSel)
    } else {
        vSel := gFilePath . "\" . vSel
        If (FileExist(vSel) and InStr(FileExist(vSel), "D")=0 ){
            MyOpenFile(HiEdit1, vSel)
        } else {
            MyGoSub("FileMenu_Open")
        }
    }
    vSel :=
    return

FileMenu_Open:
    FileSelectFile, fn, 3, %gFilePath% , Open a file
    if Errorlevel
        return
    MyOpenFile(HiEdit1, fn)
    return

FileMenu_OpenTemplate:
    FileSelectFile, fn, 3, O:\MyProfile\editor\templates, Open a template
    If Errorlevel {
        return
    }

    FileRead, iText, %fn%
    MySendText(HiEdit1,iText)
    return

FileMenu_Save:
    If FileExist(HE_GetFileName(HiEdit1)) {
        HE_SaveFile(HiEdit1, HE_GetFileName(HiEdit1))
        HE_SetModify(HiEdit1, 0)
        DoSetTitle(HiEdit1,gHWND)

        ; Record history
        vLineNumber := HE_LineFromChar(HiEdit1, HE_LineIndex(HiEdit1)) + 1
        FileAppend , %fn%@%vLineNumber%`n , %A_ScriptDir%\APEditor.his

    } else {
        MyGoSub("FileMenu_SaveAs")
    }
    return

FileMenu_SaveAs:
    FileSelectFile, fn, S 16, %gFilePath% , Save file as
    if (Errorlevel)
        return
    HE_SaveFile(HiEdit1, fn, -1)
    HE_SetModify(HiEdit1, 0)
    DoSetTitle(HiEdit1,gHWND)

    ; Record history
    vLineNumber := HE_LineFromChar(HiEdit1, HE_LineIndex(HiEdit1)) + 1
    FileAppend , %fn%@%vLineNumber%`n , %A_ScriptDir%\APEditor.his
    return

FileMenu_SaveAll:
    nFiles := HE_GetFileCount(HiEdit1)
    Loop,%nFiles%
    {
        MyGoSub("FileMenu_Save")
        MyGoSub("WindowsMenu_NextTab")
    }
    Gosub, DoGetFilePath ; Get back the correct file / path
    return

FileMenu_SaveSelection:
    HE_Copy(HiEdit1)
    HE_NewFile(HiEdit1)
    HE_Paste(HiEdit1)
    MyGoSub("FileMenu_SaveAs")
    return

FileMenu_Monitor:
; ToDo FileMenu_Monitor - this is already set but I have no event call back function
    Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
    return

FileMenu_Revert:
    HE_ReloadFile(HiEdit1)
    return

FileMenu_Print:
    HE_Print(HiEdit1)
    Return

FileMenu_Close:
    If HE_GetModify(HiEdit1,-1)
    {
        $FileName :=  HE_GetFileName(HiEdit1)
        msgbox,  3, APEditor - File not saved , Save changes to %$FileName% ?
        IfMsgBox, Yes
             MyGoSub("FileMenu_Save")
        IfMsgBox, Cancel
            Return
    }
    If HE_GetFileCount(HiEdit1) > 1
    {
        HE_CloseFile(HiEdit1, -1)
    } else {
        HE_CloseFile(HiEdit1, -1)
        ; This is where save preferences would go
        ExitApp
    }
    return

FileMenu_Exit:
    ; Link to here from GUIExit and OnExit
    nFiles := HE_GetFileCount(HiEdit1)
    Loop,%nFiles%
    {
        MyGoSub("FileMenu_Close")
    }
    return

EditMenu_Undo:
    HE_Undo(HiEdit1)
    return

EditMenu_Redo:
    HE_Redo(HiEdit1)
    return

EditMenu_Cut:
    HE_Cut(HiEdit1)
    return

EditMenu_Copy:
    HE_Copy(HiEdit1)
    return

EditMenu_Paste:
    HE_Paste(HiEdit1)
    return

EditMenu_PastePlainText:
    Runwait, "getplaintext.exe"
    HE_Paste(HiEdit1)
    return

EditMenu_CutAppend:
    Sel:=HE_GetSelText(HiEdit1)
    If (StrLen(Sel)<1)
         Return
    Clipboard:=Clipboard . Sel
    ; Now clear the selection
    HE_Clear(HiEdit1)
    return

EditMenu_CopyAppend:
    Sel:=HE_GetSelText(HiEdit1)
    If (StrLen(Sel)<1)
         Return
    Clipboard:=Clipboard . Sel
    return

EditMenu_DelEOL:
    send +{End}
    Sel:= HE_GetSelText(HiEdit1)
    StrLen(Sel)
    If StrLen(Sel)>1
    {
        send {Del}
    }
    return

EditMenu_DelBOL:
    send +{Home}
    Sel:= HE_GetSelText(HiEdit1)
    StrLen(Sel)
    If StrLen(Sel)>1
    {
        send {Del}
    }
    return

EditMenu_Goto:
    Sel:= HE_GetSelText(HiEdit1)
    cnt := HE_GetLineCount(HiEdit1)
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
        MyGotoLine(HiEdit1, line)
        return
    }
    return

EditMenu_Grep:
    ; If text is selected and no new lines, then search with it
    Sel:= HE_GetSelText(HiEdit1)
    If Sel contains `r,`n
    {
        Sel:=""
    } else {
        FindText := Sel
    }

    Run, GrepWin.exe /portable /searchpath:"%gFilePath%" /filemask:"%gFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
    return

EditMenu_BookMark:
    vLineNumber := HE_LineFromChar(HiEdit1, HE_LineIndex(HiEdit1)) + 1
    ; Add to the top of the stack
    If (LocStack%gPointer% != vLineNumber)
    {
        gPointer++
        LocStack%gPointer% := vLineNumber
    }
    vLineNumber :=
    return

EditMenu_GoBack:
   ; Check if any stored locations
    If (gPointer<1) {
        return
    }
    ; Check if current location is valid
    If (LocStack%gPointer% < 1 ) {
        return
    }
    If (LocStack%gPointer% > HE_GetLineCount(HiEdit1) ) {
        return
    }

    ; Get current location
    vLineNumber := HE_LineFromChar(HiEdit1, HE_LineIndex(HiEdit1)) + 1

    ; Search back for a different location
    While (LocStack%gPointer% = vLineNumber){
        gPointer--
        If (gPointer=0) {
            gPointer++
            Break
        }
    }

    ; Goto to location
    If (gPointer>=1) {
        MyGotoLine(HiEdit1, LocStack%gPointer%)
    }

    ; Clear variables
    vLineNumber :=
    return

EditMenu_GoForward:
   ; Check if any stored locations
    If (gPointer<1) {
        return
    }
    ; Check if current location is valid
    If (LocStack%gPointer% < 1 ) {
        return
    }
    If (LocStack%gPointer% > HE_GetLineCount(HiEdit1) ) {
        return
    }

    ; Get current location
    vLineNumber := HE_LineFromChar(HiEdit1, HE_LineIndex(HiEdit1)) + 1

    ; Search forward for a different location
    While (LocStack%gPointer% = vLineNumber) {
        Pointer2 := gPointer + 1
        If not (LocStack%Pointer2%) {
            return
        } else {
            gPointer++
        }
    }

    ; Goto to location
    MyGotoLine(HiEdit1, LocStack%gPointer%)

    ; Clear variables
    vLineNumber :=
    Pointer2 :=
    return

EditMenu_Unmark:
    ; Removes current line from location chain

    return

EditMenu_Find:
    Gosub, DoGetFilePath ; If called from the toolbar we need these instructions

    ; If text is selected and no new lines, then search with it
    Sel := HE_GetSelText(HiEdit1)
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
    ; Gosub, DoGetFilePath ; If called from the toolbar we will miss these instructions

    ; If text is selected and no new lines, then search with it
    Sel:= HE_GetSelText(HiEdit1)
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
    fp := HE_GetSel(HiEdit1)

    ; Find the previous occurence
    nfp := HE_FindText(HiEdit1, FindText, fp, 0, Flags)

    if nfp >= 4294967295		; End of file
    {
        msgbox, 8196, Search again? , Top of file - start at the end?
            IfMsgBox, No
                exit
            IfMsgBox, Yes
            {
                fl := HE_GetTextLength(HiEdit1)
                nfp := HE_FindText(HiEdit1, FindText, fl , 0, Flags)
                if (nfp = 4294967295) {
                    msgbox, 8240, String not found!, % FindText . " "
                    FindText := "" ; To stop Replace All
                    exit
                }
            }
    }

    ; Highlight found text
    HE_SetSel(HiEdit1, nfp, nfp + StrLen(FindText) )
    HE_ScrollCaret(HiEdit1)
    return

EditMenu_FindTDown:
    ; Get current file position
    fp := HE_GetSel(HiEdit1)

    ; Move on if this is the search term
    Sel := HE_GetSelText(HiEdit1)
    If (Sel = FindText) {
        fp := fp + StrLen(FindText)
    }

    ; Find the next occurence
    nfp := HE_FindText(HiEdit1, FindText, fp, -1, Flags)

    ; Deal with end of file
    if nfp >= 4294967295
    {
        msgbox, 8196, Search again? , End of file - start at the top?
            IfMsgBox, No
                exit
            IfMsgBox, Yes
            {
                nfp := HE_FindText(HiEdit1, FindText, 0, -1, Flags)
                if (nfp = 4294967295) {
                    msgbox, 8240, String not found!, % FindText . " "
                    FindText := ""  ; To stop Replace All
                    exit
                }
            }
    }

    ; Highlight found text
    HE_SetSel(HiEdit1, nfp, nfp + StrLen(FindText) )
    HE_Scroll(HiEdit1,1,0)
    HE_ScrollCaret(HiEdit1)
    return

EditMenu_FindREUp:
    msgbox, Can't do RE find upwards -yet, Sorry
    return

EditMenu_FindREDown:
; Todo EditMenu_FindREDown - Not finding ^XYZ
    ; EditMenu_FindREDown  - does not allow ^ or $ with P)
    ; Get current file position
    fp := HE_GetSel(HiEdit1)

    ; Allow for previous find
    If (REMatchLen > 0 ){
        fp := fp + REMatchLen
    }

    ; Add options
    ; https://www.autohotkey.com/docs/v1/lib/RegExMatch.htm
    ; https://www.autohotkey.com/docs/v1/misc/RegEx-QuickRef.htm#Options
    ; P to return found position
    ; m to search multiple line haystack
    REFindText := "Pm)" . FindText

    ; Line endings are giving problems!!!
    ; Pm) works for CRLF but not for LF

    ; Add options if not stated
; 	If  RegExMatch(REFindText, "^[imsxADJUXPSC]*\)"){

; 	}


    ; Display needle
    ; msgbox, %REFindText%

    ; Select all text below
    MyText := HE_GetTextRange(HiEdit1)

    ; Find the next occurence - this is a Autohotkey function
    nfp := RegExMatch(MyText, REFindText, REMatchLen, fp)

    if (nfp >= 4294967295 or nfp = 0) {
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
    HE_SetSel(HiEdit1, nfp -1, nfp + REMatchLen -1)
    HE_Scroll(HiEdit1,1,0)
    HE_ScrollCaret(HiEdit1)
    return

EditMenu_FindinFiles:
    ; If text is selected and no new lines, then search with it
    Sel:= HE_GetSelText(HiEdit1)
    If Sel contains `r,`n
    {
        Sel:=""
    } else {
        FindText := Sel
    }

    Run, GrepWin.exe /portable /searchpath:"%gFilePath%" /filemask:"*.*" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
    return

EditMenu_Replace:
    Gosub, DoGetFilePath ; If called from the toolbar we need these instructions

    ; If text is selected and no new lines, then search with it
    Sel:= HE_GetSelText(HiEdit1)
    If Sel contains `r,`n
    {
        Target:= Sel
        ReplaceText:=""
        ReplaceCMD := Sel . "|"
    } else {
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
    If (FindText="") {
        msgbox, No string to find
        return
    }
    If (ReplaceText="") {
        msgbox, No replacement string
        return
    }
    If (FindText = HE_GetSelText(HiEdit1)) {
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
; ToDo EditMenu_ReplaceAll - problem getting it to select whole document
; ToDo EditMenu_ReplaceAll - do we need to reposition cursor?
    Gosub, DoGetFilePath ; If called from the toolbar we need these instructions

    ; Remember the current`position
    CurrChar := HE_LineIndex(HiEdit1, -1)

    ; If text is selected and no new lines, then search with it
    Sel:= HE_GetSelText(HiEdit1)
    If Sel contains `r,`n
    {
        Target:= Sel
        ReplaceText:=""
        ReplaceCMD := Sel . "|"
    } else {
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
    If (RepArray0 < 2) {
        msgbox, Too few parameters
        return
    }
    If (FindText="") {
        msgbox, No string to find
        return
    }
    If (ReplaceText="") {
        msgbox, No replacement string
        return
    }
    If (FindText = HE_GetSelText(HiEdit1)) {
        ; do the replacement
        Send, %ReplaceText%
    }

    If (ReplaceOptions="All" or ReplaceOptions="all"  or ReplaceOptions="ALL") {
        If (Target="") {
            HE_SetSel(HiEdit1, 0, -1)
            Target := HE_GetSelText(HiEdit1)
            StringReplace, Output, Target, %FindText%, %ReplaceText%, All
            HE_ReplaceSel(HiEdit1,Output)
        } else {
            StringReplace, Output, Target, %FindText%, %ReplaceText%, All
            HE_ReplaceSel(HiEdit1,Output)
        }
    }

    ; Restore position
    HE_SetSel(HiEdit1,CurrChar,CurrChar)
    HE_ScrollCaret(HiEdit1)
    return

EditMenu_Replaceinfiles:
    Sel:= HE_GetSelText(HiEdit1)
    If Sel contains `r,`n
    {
        Sel:=""
    } else {
        FindText := Sel
    }

    MyGoSub("FileMenu_Save")
    Gosub, WinDisable
    Runwait, GrepWin.exe /portable /searchpath:"%gFilePath%" /filemask:"%gFileName%" /searchfor:"%Sel%"  /size:-1 /s:yes /h:yes,""
    Gosub, WinEnable
    Gosub, FileMenu_Revert
    return

SelectMenu_Word:
    MouseMove, %A_CaretX%, %A_CaretY%
    Send, {LButton}{LButton}
    return

SelectMenu_BOL:
    send +{Home}
    return

SelectMenu_EOL:
    send +{End}
    return

SelectMenu_LineDown:
    HE_GetSel(HiEdit1,BlockStart,BlockEnd)
    CaretLine := HE_LineFromChar(HiEdit1,HE_LineIndex(HiEdit1,-1))
    StartLine := HE_LineFromChar(HiEdit1,BlockStart)
    EndLine:= HE_LineFromChar(HiEdit1,BlockEnd)
    ; I'm not sure all these are used:)
    If (StartLine = EndLine) {
        ;Selection on one line
        Send {Home}
        Send +{End}
        Send +{Right}
        return
    }
    If (CaretLine = EndLine) {
        ; Selection is on this line
        Send +{End}
        ; Need to move it on next time
        Send +{Right}
        Send +{End}
        return
    }
    If (CaretLine < EndLine) {
        ; We where selecting upwards and need to unselect
        Send +{End}
        Send +{Right}
        return
    }
    msgbox, Error: C %CaretLine% S %StartLine% E %Endline%
    return

SelectMenu_LineUp:
    HE_GetSel(HiEdit1,BlockStart,BlockEnd)
    CaretLine := HE_LineFromChar(HiEdit1,HE_LineIndex(HiEdit1,-1))
    StartLine := HE_LineFromChar(HiEdit1,BlockStart)
    EndLine:= HE_LineFromChar(HiEdit1,BlockEnd)
    ; I'm not sure all these are used:)
    If (StartLine = EndLine) {
        ;Selection on one line
        Send {End}
        Send +{Home}
        If (BlockStart = HE_LineIndex(HiEdit1,-1)) {
            Send +{Left}
            Send +{Home}
        }
        return
    }
    If (CaretLine = EndLine) {
        ; We were selecting downwards and need to unselect
        Send +{End}
        Send +{Home}
        Send +{Left}
        return
    }
    If (CaretLine = StartLine) {
        ; We were selecting upwards and need to continue
        Send +{Left}
        Send +{Home}
        return
    }
    If (CaretLine < EndLine) {
        ; We are selecting upwards and need to extend
        Send +{Home}
        Send +{Left}
        Send +{Home}
        return
    }
    msgbox, Error: C %CaretLine% S %StartLine% E %Endline%
    return

SelectMenu_All:
    HE_SetSel(HiEdit1, 0, -1)
    return

FormatMenu_UpperCase:
    HE_ConvertCase(HiEdit1,"upper")
    return

FormatMenu_LowerCase:
    HE_ConvertCase(HiEdit1,"lower")
    return

FormatMenu_ProperCase:
    HE_ConvertCase(HiEdit1,"capitalize")
    return

FormatMenu_ReverseCase:
    HE_ConvertCase(HiEdit1)
    return

EOLMenu_UnixLF:
; ToDo EOLMenu_UnixLF
    return

EOLMenu_MacCR:
; ToDo EOLMenu_MacCR
    return

EOLMenu_WinCRLF:
; ToDo EOLMenu_WinCRLF - this is too slow  - use an external tool
    ; Remember the current position
    CurrChar := HE_LineIndex(HiEdit1, -1)

    ; Break types - created outside the Loop!
    HardBreak 	:= Chr(13) . Chr(10)		; CRLF 	`r`n
    SoftBreak 	:= Chr(10)				    ; LF		`n
    EOF			:= ""                       ; Can't make Chr(0) . Chr(0)

    ; Loop through the whole file testing the EOL
    $Index := 1
    While ($Index < HE_GetLineCount(HiEdit1) ){
        Text 		:= HE_GetLine(HiEdit1, $Index-1)
        FirstChar 	:= HE_LineIndex(HiEdit1, $Index-1)
        LastChar 	:= FirstChar + HE_LineLength(HiEdit1, $Index-1)

        ; Get the next two chars to see what type of EOL characters are present
        NextChar	:= HE_GetTextRange(HiEdit1, LastChar, LastChar+2)
        If (NextChar = HardBreak) {
            ;
        } else if (SubStr(NextChar, 1 , 1) = SoftBreak) {
            ; Add hardbreak
            Text := Text . HardBreak
            ; Change text and redisplay - so we can harvest the next two chars
            ; the +1 stops duplication of the last char - can't work out why!
            HE_SetSel(HiEdit1,FirstChar,LastChar+1)
            HE_ReplaceSel(HiEdit1, Text)

            ; Get back to left hand edge - can't kill autoscroll
            HE_SetSel(HiEdit1,FirstChar,FirstChar)
            HE_ScrollCaret(HiEdit1)
        } else if (NextChar = EOF) {
            ; This is here to identify EOF - we should not get here
            msgbox, %$Index%   -  this is an EOF break
        } else {
            ; Unknown EOL - we should not get here
            msgbox, % $Index   "-  this is an  unknown EOL code: " Asc(SubStr(NextChar, 1 , 1) ) A_Space Asc(SubStr(NextChar, 2 , 1) )
        }

        ; Increment counter
        $Index++
    }
    ; Restore position
    HE_SetSel(HiEdit1,CurrChar,CurrChar)
    HE_ScrollCaret(HiEdit1)
    return

InsertMenu_File:
    FileSelectFile, ifn, 3, %gFilePath%, Insert file
    FileRead, iText, %ifn%
    MySendText(HiEdit1,iText)
    return

InsertMenu_LineBelow:
    send {End}{Enter}
    return

InsertMenu_Date:
    FormatTime,date,YYYYMMDDHH24MISS,dd-MM-yyyy
    MySendText(HiEdit1,date)
    return

InsertMenu_Time:
    FormatTime,time,YYYYMMDDHH24MISS,HH':'mm
    MySendText(HiEdit1,time)
    return

InsertMenu_Stamp:
    FormatTime,date,YYYYMMDDHH24MISS,yyyy-MM-dd
    FormatTime,time,YYYYMMDDHH24MISS,HH':'mm
    MySendText(HiEdit1,date . " " . time . " ")
    return

InsertMenu_FileName:
    Sendinput, % HE_GetFileName(HiEdit1)
    return

InsertMenu_GetFileName:
    FileSelectFile, ifn, 3, gFilePath, Get file name
    Sendinput, % ifn
    return

InsertMenu_RelFileName:
    FileSelectFile, ifn, 3, gFilePath, Get file name
    ifn := MyGetRelPath(HE_GetFileName(HiEdit1,-1),ifn)
    Sendinput, % ifn
    return

AltMenu_Goto:
; find matches in current file
    target := gFilePath . "\" . gFileName
    ; fzf to find matches
    vClip := Clipboard
    CMD := "cmd.exe /c cat.exe -n " . target  . " | fzf.exe --prompt=""> goto "" --no-sort --tac --color prompt:110 --print0 | clip.exe "
    RunWait, %CMD%, %gFilePath% , max
    target := Clipboard
    ; Remove trailing CRLF and leading spaces
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    target := RegExReplace(target,"^[ \t]*","")

    ; Extract line number
    StringSplit,target,target,%A_Tab%
    If target1 > 0
    {
        MyGotoLine(HiEdit1,target1)
    }

    ; Clear/reset variables
    Clipboard := vClip
    vClip :=
    target := ""
    line := ""

    ; Goto selection

    return

AltMenu_FindinFiles:
; Use findstr.exe as it is part of WindowsTM
    ; If text is selected and no new lines, then search with it
    Sel := HE_GetSelText(HiEdit1)
    If Sel contains `r,`n
    {
        Sel := ""
    }

    ; Ask for text to find - modal dialog
    ; https://ss64.com/nt/findstr.html
    Gui, +OwnDialogs
    InputBox, FindText, Find in Files, Enter findstr.exe /npi query, , 400, 125, , , , ,%Sel%
    if ErrorLevel
        return

    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c findstr.exe /npi " . FindText  .  " " . gFilePath . "\*.* | fzf.exe --print0 | clip.exe"
    RunWait, %CMD%, , max
    target :=  Clipboard
    ; Remove trailing CRLF and leading spaces
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    target := RegExReplace(target,"^[ \t]*","")
    ; Split string
    StringSplit,target,target,:
    line := target3
    target := target1 . ":" . target2
    ; Load file
    MyOpenFile(HiEdit1,target)
    MyGotoLine(HiEdit1,line)

    ; Clear/reset variables
    Clipboard := vClip
    target := ""
    return

AltMenu_InsertLine:
; Select the file with lines to copy
    If FileExist("O:\MyProfile\editor\insertions\api." . gFileExt) {
        target := "O:\MyProfile\editor\insertions\api." . gFileExt
    } else {
        target := "O:\MyProfile\editor\insertions\api"
    }

    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c cat.exe " . target  .  " | fzf.exe --print0 | clip.exe"
    RunWait, %CMD%, , max
    Sendinput, %clipboard%

    ; Clear/reset variables
    Clipboard := vClip
    vClip :=
    target := ""

    return

AltMenu_EditLine:
; Select the file with lines to edit
    If FileExist("O:\MyProfile\editor\insertions\api." . gFileExt) {
        target := "O:\MyProfile\editor\insertions\api." . gFileExt
        MyOpenFile(HiEdit1, target)
    }

    ; Clear/reset variables
    target := ""
    return

AltMenu_File:
; Insert file contents
    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c fzf.exe --prompt=""> insert "" --preview ""bat.exe --style=numbers --color=always --line-range :500 {}"" --color prompt:110 | clip.exe "
    RunWait, %CMD%, %gFilePath% , max
    target := gFilePath . "\" . Clipboard
    ; Remove trailing CRLF
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    IfExist, %target%
    {
        FileRead, iText, %target%
        MySendText(HiEdit1,iText)
    }

    ; Clear/reset variables
    Clipboard := vClip
    vClip := ""
    iText := ""

    return

AltMenu_Open:
; Open in new tab
    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c fzf.exe --prompt=""> open "" --preview ""bat.exe --style=numbers --color=always --line-range :500 {}"" --color prompt:110 | clip.exe "
    RunWait, %CMD%, %gFilePath% , max
    ; Handle cancel - this smalls bad
    If (Clipboard != "") 
    {
	    IfExist, %gFilePath%
	    {
	        target := gFilePath . "\" . Clipboard
	    } Else {
	        target := A_ScriptDir . "\" . Clipboard
	    }
	    ; Remove CR LF
	    StringReplace, target, target, `n, , A
	    StringReplace, target, target, `r, , A
	    IfExist, %target%
	    {
	        MyOpenFile(HiEdit1, target)
	    }
	}
    ; Clear/reset variables
    Clipboard := vClip
    vClip := ""
    iText := ""

    return

AltMenu_Snippet:
; Insert file contents
    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c fzf.exe --prompt=""> snippet "" --preview ""bat.exe --style=numbers --color=always --line-range :500 {}"" --color prompt:110 | clip.exe "
    RunWait, %CMD%, O:\MyProfile\editor\snippets\ , max
    target := "O:\MyProfile\editor\snippets\" . Clipboard
    ; Remove trailing CRLF
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    IfExist, %target%
    {
        FileRead, iText, %target%
        MySendText(HiEdit1,iText)
    }

    ; Clear/reset variables
    Clipboard := vClip
    vClip := ""
    iText := ""

    return

AltMenu_EditSnippet:
; Insert file contents
    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c fzf.exe --prompt=""> snippet "" --preview ""bat.exe --style=numbers --color=always --line-range :500 {}"" --color prompt:110 | clip.exe "
    RunWait, %CMD%, O:\MyProfile\editor\snippets\ , max
    target := "O:\MyProfile\editor\snippets\" . Clipboard
    ; Remove trailing CRLF
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    IfExist, %target%
    {
       MyOpenFile(HiEdit1, target)
    }

    ; Clear/reset variables
    Clipboard := vClip
    vClip := ""
    iText := ""

    return

AltMenu_OpenTemplate:
; Insert file contents
    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c fzf.exe --prompt=""> template "" --preview ""bat.exe --style=numbers --color=always --line-range :500 {}"" --color prompt:110 | clip.exe "
    RunWait, %CMD%, O:\MyProfile\editor\templates\ , max
    target := "O:\MyProfile\editor\templates\" . Clipboard
    ; Remove trailing CRLF
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    IfExist, %target%
    {
        FileRead, iText, %target%
        MySendText(HiEdit1,iText)
    }

    ; Clear/reset variables
    Clipboard := vClip
    vClip := ""
    iText := ""

    return

AltMenu_EditTemplate:
; Insert file contents
    ; Note use of clipboard - can't capture STDOUT
    vClip := Clipboard
    CMD := "cmd.exe /c fzf.exe --prompt=""> template "" --preview ""bat.exe --style=numbers --color=always --line-range :500 {}"" --color prompt:110 | clip.exe "
    RunWait, %CMD%, O:\MyProfile\editor\templates\ , max
    target := "O:\MyProfile\editor\templates\" . Clipboard
    ; Remove trailing CRLF
    StringReplace, target, target, `n, , A
    StringReplace, target, target, `r, , A
    IfExist, %target%
    {
        MyOpenFile(HiEdit1, target)
    }

    ; Clear/reset variables
    Clipboard := vClip
    vClip := ""
    iText := ""
    return
    
BlockMenu_Indent:
    Send {Tab}
    Gosub, DoGetBlock
    return

BlockMenu_Outdent:
    Gosub, DoGetBlock
    Send +{Tab}
    return

BlockMenu_Duplicate:
    Gosub, DoGetBlock
    Send {Down}{Home}{Enter}{Up}
    Gosub, DoSendBlock
    return

BlockMenu_Yank:
    Gosub, DoGetBlock
    Send {Del}
    Send {Del}
    Return

BlockMenu_Join:
    Gosub, DoGetBlock
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
    Gosub, DoSendBlock
    return

BlockMenu_ShiftUp:
    Gosub, DoGetBlock
    SendInput {Del}{Del}{Up}{Enter}{Up}
    Gosub, DoSendBlock
    return

BlockMenu_ShiftDown:
    Gosub, DoGetBlock
    SendInput {Del}{Del}{Down}{Enter}{Up}
    Gosub, DoSendBlock
    return

BlockMenu_Comment:
    Gosub, DoGetBlock
    Block := "/*" . A_Tab . Block . A_Tab . "*/"
    Gosub, DoSendBlock
    return

BlockMenu_BlockComment:
    Gosub, DoGetBlock
    ; This needs to know prefix by filetype
    Block := RegExReplace(Block,"m)^.","; $0")
    Gosub, DoSendBlock
    return

PreMenu_Bullet:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^.","-	$0")
    Gosub, DoSendBlock
    return

PreMenu_Number:
    Gosub, DoGetBlock
    MyCount := 1
    While (MyCount > 0){
        Block := RegExReplace(Block,"m)^[a-zA-Z]", MyCount . ".	$0", OutputVarCount , 1 )
        MyCount++
        MyCount := MyCount * OutputVarCount
    }
    Gosub, DoSendBlock
    return

PreMenu_Renumber:
    Gosub, DoGetBlock
    MyGoSub("PreMenu_ClearPrefix")
    MyGoSub("PreMenu_Number")
    return

PreMenu_1LineComment:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^.","; $0")
    Gosub, DoSendBlock
    return

PreMenu_2LineComment:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^.","# $0")
    Gosub, DoSendBlock
    return

PreMenu_3LineComment:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^.","// $0")
    Gosub, DoSendBlock
    return

PreMenu_4LineComment:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^.","-- $0")
    Gosub, DoSendBlock
    return

PreMenu_5LineComment:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^.",":: $0")
    Gosub, DoSendBlock
    return

PreMenu_ClearPrefix:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^(; |[0-9]+\.	|-	)","")
    Block := RegExReplace(Block,"m)^(# |[0-9]+\.	|-	)","")
    Block := RegExReplace(Block,"m)^(// |[0-9]+\.	|-	)","")
    Block := RegExReplace(Block,"m)^(-- |[0-9]+\.	|-	)","")
    Block := RegExReplace(Block,"m)^(- |[0-9]+\.	|-	)","")
    Gosub, DoSendBlock
    return

SortMenu_Ascending:
    Gosub, DoGetBlock
    Sort, Block, C
    Gosub, DoSendBlock
    return

SortMenu_Descending:
    Gosub, DoGetBlock
    Sort, Block, CR
    Gosub, DoSendBlock
    return

SortMenu_Integer:
    Gosub, DoGetBlock
    Sort, Block, N
    Gosub, DoSendBlock
    return

SortMenu_RemoveDups:
    Gosub, DoGetBlock
    Sort, Block, U
    Gosub, DoSendBlock
    return

TrimMenu_RTrim:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)[ \t]*$","")
    Gosub, DoSendBlock
    return

TrimMenu_LTrim:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)^[ \t]*","")
    Gosub, DoSendBlock
    return

TrimMenu_FullTrim:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)[ \t]*$","")
    Block := RegExReplace(Block,"m)^[ \t]*","")
    Gosub, DoSendBlock
    return

TrimMenu_EmptyLines:
    Gosub, DoGetBlock
    Block := RegExReplace(Block,"m)[ \t]*$","")
    Block := RegExReplace(Block,"m)^[ \t]*","")
    StringReplace, Block, Block, `r`n`r`n, `r`n, A
    Gosub, DoSendBlock
    return

ProjectMenu_Run:
    IfNotExist, %gFilePath%
    {
        return
    }
    ; Save the file
    MyGoSub("FileMenu_Save")
    MyToolsCall(HiEdit1,"shelexec.exe",HE_GetFileName(HiEdit1))
    return

ProjectMenu_Makeit:
    If FileExist(gFilePath . "\MakeIt.bat")
    {
        MyGoSub("FileMenu_SaveAll")
        MyToolsCall(HiEdit1,"shelexec.exe", gFilePath . "\MakeIt.bat")
    }
    return

ProjectMenu_JobsToDo:
    If FileExist(gFilePath . "\Todo.txt")
    {
        MyOpenFile(HiEdit1, gFilePath .  "\Todo.txt")
    }
    return

ProjectMenu_Folder:
    If FileExist(gFilePath)
    {
        Run, shelexec.exe %gFilePath%
    }
    return

FileMenu_SaveBackup:
ProjectMenu_Backup:
    IfNotExist, %gFilePath%
    {
        return
    }
    ; Check or create backup path
    MyBackupPath := gFilePath . "\zBackup\"
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
    MyBackupFile := A_YYYY . "_" . A_MM . "_" . A_DD . "_" . MyBackupFile . "_" . gFileName
    MyBackupFile := MyBackupPath . MyBackupFile

    ; Copy the old file to backup - if it exists!
    fn = %gFilePath%\%gFileName%
    If (FileExist(fn)){
        FileCopy, %fn%, %MyBackupFile% ,1
    }

    ; Save the current version
    MyGoSub("FileMenu_Save")

    return

FileMenu_ViewBackup:
ProjectMenu_Versions:
    IfNotExist, %gFilePath%
    {
        return
    }
    MyBackupPath := gFilePath . "\zBackup\"
    IfNotExist, %MyBackupPath%
    {
        msgbox, No backup directory
        return
    } else {
        FileSelectFile, fn, 3,  %MyBackupPath%,  "Select a backup file ...", (*%gFileName%)
        If Errorlevel
            return
        MyOpenFile(HiEdit1, fn)
    }
    return

ToolsMenu_$hell:
    ; Reset FileName as can be called called from button bar
    Gosub, DoGetFilePath
    Run, %ComSpec% , %gFilePath%, max
    return

ToolsMenu_Calculate:
; Todo ToolsMenu_Calculate - not sure if this is right yet
    Gosub, DoGetBlock
    If (Block="") {
        return
    }

        Run, lua51.bat -l extensions -i -e "%Block%" ,""
    return

ToolsMenu_Diff:
    If FileExist(gFilePath)
    {
        Run, TextDiff.exe %A_Space% %gFilePath%\%gFileName% %A_Space% %gFilePath%\%gFileName%
    }
    return

ToolsMenu_SpellCheck:
    Sel := HE_GetSelText(HiEdit1)
    $SpellCheck(HiEdit1, Sel)
    return

OptionsMenu_Font:
    if Dlg_Font(gFont, gStyle, pColor, true, gHWND)
        HE_SetFont(HiEdit1, gStyle "," gFont)
    return

OptionsMenu_Tabs:
    InputBox, w, SetTabWidth ,Set Tab Width,,400,125,,,,,4
    if ErrorLevel
        return
    HE_SetTabWidth(HiEdit1, w)
    return

OptionsMenu_SytaxColours:
    FileSelectFile, fn, 3, %A_ScriptDir%, "Select a syntax highlight file ...", (*.hes)
    HE_SetKeywordFile(fn)
    return

; OptionsMenu_Colours:  ; Can't update the control without Exec function!!
; 	FileSelectFile, fn, 3, %A_ScriptDir%\hes, "Select a colour file ...", (*.hes)
;    HE_SetColors(HiEdit1, colours)
; 	return

OptionsMenu_Light:

    ; ** Solarized colour theme from http://ethanschoonover.com/solarized **

    BASE03 		=	0x362B00
    BASE02 		=	0x423607
    BASE01 		=	0x756E58
    BASE00 		=	0x837B65
    BASE0 		=	0x969483
    BASE1 		=	0xA1A193
    BASE2 		=	0xD5E8EE
    BASE3 		=	0xE3F6FD
    YELLOW 		=	0x0089B5
    ORANGE 		=	0x164BCB
    RED 		=	0x2F32DC
    MAGENTA 	= 	0x8236D3
    VIOLET 		=	0xC4716C
    BLUE 		=	0xD28B26
    CYAN 		=	0x98A12A
    GREEN 		=	0x009985

    TEXT		= %BASE0%
    BACK 		= %BASE3%
    SELTEXT		= %BASE2%
    ACTSELBACK 	= %BLUE%
    INSELBACK	= %BASE1%
    LINENUMBER	= %BASE1%
    SELBACKBAR	= %BASE2%
    NONPRINTBACK= %BASE0%
    NUMBER 		= %CYAN%

;  How to set these below

    DELIMITERS		:= MyHesDel(BLUE)
    DELIMITERS		:= MyHesDel(RED)
    DIRECTIVES		:= MyHesCol(RED)
    COMMANDS		:= MyHesCol(RED)
    FUNCTIONS		:= MyHesCol(BLUE)
    METHODS			:= MyHesCol(VIOLET)
    VARIABLES		:= MyHesCol(GREEN)
    STRINGS			:= MyHesCol(CYAN)
    COMMENTS		:= MyHesCol(LINENUMBER)
    KEYS			:= MyHesCol(RED)

    colours=
    (
        Text 			= %TEXT%
        Back 			= %BACK%
        SelText 		= %SELTEXT%
        ActSelBack 		= %ACTSELBACK%
        InSelBack 		= %INSELBACK%
        LineNumber 		= %LINENUMBER%
        SelBarBack 		= %SELBACKBAR%
        NonPrintableBack= %NONPRINTBACK%
        Number			= %NUMBER%
    )
    HE_SetColors(HiEdit1, colours)
    Menu, OptionsMenu, Check, &Light
    Menu, OptionsMenu, UnCheck, &Dark
    return

OptionsMenu_Dark:

    ; ** Solarized colour theme from http://ethanschoonover.com/solarized **

    BASE03 	=	0x362B00
    BASE02 	=	0x423607
    BASE01 	=	0x756E58
    BASE00 	=	0x837B65
    BASE0 	=	0x969483
    BASE1 	=	0xA1A193
    BASE2 	=	0xD5E8EE
    BASE3 	=	0xE3F6FD
    BASE3 	=	0x03F6FD
    YELLOW 	=	0x0089B5
    ORANGE 	=	0x164BCB
    RED 	=	0x2F32DC
    MAGENTA = 	0x8236D3
    VIOLET 	=	0xC4716C
    BLUE 	=	0xD28B26
    CYAN 	=	0x98A12A
    GREEN 	=	0x009985

    TEXT		= %BASE0%
    BACK 		= %BASE03%
    SELTEXT		= %BASE2%
    ACTSELBACK 	= %BLUE%
    INSELBACK	= %BASE1%
    LINENUMBER	= %BASE1%
    SELBACKBAR	= %BASE02%
    NONPRINTBACK= %BASE0%
    NUMBER 		= %CYAN%

;  How to set these below

    DELIMITERS		:= MyHesDel(BLUE)
    DIRECTIVES		:= MyHesCol(RED)
    COMMANDS		:= MyHesCol(RED)
    FUNCTIONS		:= MyHesCol(BLUE)
    METHODS			:= MyHesCol(VIOLET)
    VARIABLES		:= MyHesCol(GREEN)
    STRINGS			:= MyHesCol(CYAN)
    COMMENTS		:= MyHesCol(LINENUMBER)
    KEYS			:= MyHesCol(RED)

    colours=
    (
        Text 			= %TEXT%
        Back 			= %BACK%
        SelText 		= %SELTEXT%
        ActSelBack 		= %ACTSELBACK%
        InSelBack 		= %INSELBACK%
        LineNumber 		= %LINENUMBER%
        SelBarBack 		= %SELBACKBAR%
        NonPrintableBack= %NONPRINTBACK%
        Number			= %NUMBER%
    )

    HE_SetColors(HiEdit1, colours)
    Menu, OptionsMenu, Check, &Dark
    Menu, OptionsMenu, UnCheck, &Light
    return

OptionsMenu_FullScreen:
    WinMaximize, ahk_id %gHWND%
    return

OptionsMenu_AutoIndent:
    Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
    HE_AutoIndent(HiEdit1, gAutoIndent := !gAutoIndent)
    return

OptionsMenu_LineNumbers:
    Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%
    gLineNumbers := !gLineNumbers
    HE_LineNumbersBar(HiEdit1, gLineNumbers ? "automaxsize" : "hide")
    return

WindowsMenu_NextTab:
    MyTAB := HE_GetCurrentFile(HiEdit1)
    MyTAB++
    MaxTAB := HE_GetFileCount(HiEdit1)
    If (MyTAB < MaxTAB) {
        HE_SetCurrentFile(HiEdit1, MyTAB)
    } else {
        HE_SetCurrentFile(HiEdit1, 0)
    }
    return

WindowsMenu_PrevTAB:
    MyTAB := HE_GetCurrentFile(HiEdit1)
    MaxTAB := HE_GetFileCount(HiEdit1)
    If (MyTAB = 0 ) {
        HE_SetCurrentFile(HiEdit1, (MaxTAB-1))
    } else {
        MyTAB := MyTAB-1
        HE_SetCurrentFile(HiEdit1, MyTAB)
    }
    return

WindowsMenu_FileList:
    MouseGetPos, x, y
    HE_ShowFileList(HiEdit1,3,88)
    return

HelpMenu_ToDo:
    MyOpenFile(HiEdit1, A_ScriptDir . "\ToDo.txt")
    return

HelpMenu_Contents:
    MyOpenFile(HiEdit1, A_ScriptDir . "\APEditor.mmd")
    return

HelpMenu_Keys:
    MyOpenFile(HiEdit1, A_ScriptDir . "\APEditor.mmd")
    return

HelpMenu_Source:
    MyOpenFile(HiEdit1, A_ScriptDir . "\source\APEditor.ahk")
    return

HelpMenu_About:
    msg := "A programmable editor in AHK " . A_AHKVersion . "`n" . A_ScriptDIR . "`n`n"
        . "  HiEdit control " . HiEdit1 . " is copyright of Antonis Kyprianou:`n"
        . "     http://www.winasm.net`n`n"
        . "  AHK wrapper by Majkinetor:`n"
        . "     https://github.com/majkinetor/mm-autohotkey`n`n"
        . "  Editor functionality by Gavin Holt`n"
        . "     https://github.com/Gavin-Holt/APEditor`n`n"
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
    gStyle := "s" . (SubStr(gStyle, 2) + 1)
    HE_SetFont(HiEdit1, gStyle "," gFont)
    HE_SetTabWidth(HiEdit1,gTAB)
    return

FontDec:
    gStyle := "s" . (SubStr(gStyle, 2) - 1)
    HE_SetFont(HiEdit1, gStyle "," gFont)
    HE_SetTabWidth(HiEdit1,gTAB)
    return

; GuiEvents see also OnMessage in help
; I tried to move this section and it wouldn't compile
GuiContextMenu:
    return

GuiSize:
    return

GuiEscape:
    ;MyGoSub("FileMenu_Close")
    ; Disabled to allow esc from message boxes
    return

GuiClose:
OnExit:
    MyGoSub("FileMenu_Exit")
    return

GuiDropFiles:
    Loop, parse, A_GuiEvent, `n
    {
        fn := A_LoopField
        N := HE_GetFileCount(HiEdit1)
        Loop,%N%
        {
            idx := A_Index-1
            nf := HE_GetFileName(HiEdit1,idx)
            IfInString,nf,%fn%
            {
                HE_SetCurrentFile(HiEdit1,idx)
                Break
            }
            If (N = A_Index)
            {
                MyOpenFile(HiEdit1,fn)
                Break
            }
        }
    }
    Return

; Includes
; Library files
#include inc\Attach.ahk
#include inc\Dlg.ahk
#include inc\HIEdit.ahk

; Libs by Jballi
#include inc\HiEdit_Print.ahk
#include inc\Spell.ahk

; Plugins - can't load dynamically and are compiled into the exe.
#include plg\Autocorrect.ahk
#include plg\DyslexicTypos.ahk
#include plg\Grammar.ahk
#include plg\SpellCheck.ahk
#include plg\TabExpand.ahk

