# APEditor

## Introduction

In an attempt to reduce _cognitive load_ I have resurrected one of my old projects in Autohotkey. 
My previous version was overloaded, attempting to be an IDE, so I have removed as much a possible.

## Perfection

Antoine de Saint-Exupery said _"Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away"_.

- No launching of other applications (except grep)
- No CVS
- No unused shortcuts

I should remove the toolbar, but it helps me remember my context, and look great!

## User interface

The script provides a bare minimum of user interface elements:

- Menus
- Toolbar
- Tabbar
- Keyboard shortcuts
- Input boxes
- File dialoges

## Requirements

This is the compiled version of my AHK scripted editor:
1. APEditor.exe
2. APEditor.dll - I have renamed from HiEdit.dll to keep the files together
3. APEditor.hes - Keyword file for highlighting
4. .\img\*.* - Image files for the toolbar

Also uses external tools:
1. %comspec%
2. GrepWin.exe
3. GetPlainText.exe
4. Shelexec.exe
5. TextDiff.exe

## Functionality

The script uses a very capable edit control (HiEdit.dll) with all the ususal keyboard shortcuts.

I have intercepted a few calls for my own use:

- 	+{Down}     My_CMDCall("SelectMenu_LineDown")
- 	+{up}       My_CMDCall("SelectMenu_LineUp")
-   ^{BS}       Send +^{Left}{BS}

Additional functionality is added using Autohotkey, and specifically the wrapper for the edit control (HiEdit.ahk).

Choosing the minimum set of additional functions has been interesting.

Rather than copying all the functions I have seen in other editors, I have tried to limit myself:

- Functions I regularly
- Functions that are __really__ useful when needed.

The source code can be modified to add functionality, within the boundaries of the UI and underlying edit control. 
However, please note there is no way to _word wrap_ in this control.

My added fuctions are listed below:

1.	Revert to disk version
2.	Open selected filename
3.	Insert template
4.	Insert file/filename
5.	Save/open local backup
6.	Paste plain text
7.	Kill to BOL/EOL
8.	Goto
9.	Mark and move
10.	Find and replace text
11.	Find regular expressions
12.	Find and replace in files (external tool)
13.	Duplicate line/block
14.	Delete line/block
15.	Move line/block up/down
16.	Prefix line/block
17.	Sort
18.	Trim
19.	Change case
20.	Change EOL
21.	Project actions
22. Mouse wheel to zoom
23. A few external tools

## Keyboard shortcuts

I have implemented some of my own keyboard shortcuts, and again choosing the minimum set has been interesting.




