; This is my spellcheck plugin - built upon the shoulders of giants!
; Adding words to the user_dict.dic does not work!
; Requirements
;	Designed to be #included in APEditor
;		https://github.com/Gavin-Holt/APEditor
; 		Using very old AHK/AHK2EXE (ver 1.0.48.05)
; 	Spell.ahk (2.0) jballi
;		https://www.autohotkey.com/boards/viewtopic.php?t=4971

#include inc\Spell.ahk

$SpellCheck(HiEdit1, sText){

	; Define the path to the hunspell dictionaries
	;   note I keep my user_dict.dic in here also - read lower down
	DicPath := "O:\MyProfile\editor\hunspell\"

    ; Destroy previous iterations
    Spell_Uninit(hSpell)
    tText =
    Replacement =

	; Initialize
	if not Spell_Init(hSpell,DicPath . "en_GB.aff", DicPath . "en_GB.dic", A_ScriptDir . "\Hunspellx86.dll")
		return

	; Load the custom dictionary
	if not Spell_InitCustom(hSpell,DicPath . "user_dict.dic","L")
		return

	; Check for selection
	if Strlen(sText) < 1
	{
		sText := MyGetAllText(HiEdit1)
	}
	if Strlen(sText) < 1
	{
		; This is an empty file
		msgbox, No text to spellcheck
		return
	}

    ; Pad the text
    sText = %A_Space%%sText%%A_Space%

	; Remove all unwanted characters
	StringReplace, tText, sText, %A_Tab%, %A_Space% , All
	StringReplace, tText, tText, `r, %A_Space% , All
	StringReplace, tText, tText, `n, %A_Space% , All
	StringReplace, tText, tText, `,, %A_Space% , All
	StringReplace, tText, tText, `;, %A_Space% , All
	StringReplace, tText, tText, `%, %A_Space% , All
	StringReplace, tText, tText, ., %A_Space% , All
	StringReplace, tText, tText, ?, %A_Space% , All
	StringReplace, tText, tText, !, %A_Space% , All
	StringReplace, tText, tText, ), %A_Space% , All
	StringReplace, tText, tText, (, %A_Space% , All
	StringReplace, tText, tText, [, %A_Space% , All
	StringReplace, tText, tText, ], %A_Space% , All
	StringReplace, tText, tText, #, %A_Space% , All
	StringReplace, tText, tText, @, %A_Space% , All
	StringReplace, tText, tText, ~, %A_Space% , All
	StringReplace, tText, tText, $, %A_Space% , All
	StringReplace, tText, tText, |, %A_Space% , All
	StringReplace, tText, tText, \, %A_Space% , All
	StringReplace, tText, tText, /, %A_Space% , All
	StringReplace, tText, tText, ", %A_Space% , All
; 	StringReplace, tText, tText, ', %A_Space% , All
	StringReplace, tText, tText, :, %A_Space% , All
	StringReplace, tText, tText, _, %A_Space% , All
	StringReplace, tText, tText, %A_Space%-%A_Space%, %A_Space% , All
	StringReplace, tText, tText, %A_Space%%A_Space%, %A_Space% , All
	StringReplace, tText, tText, %A_Space%%A_Space%, %A_Space% , All
	StringReplace, tText, tText, %A_Space%%A_Space%, %A_Space% , All

	; Filter down to just misspelled words
	Loop, Parse, tText, %A_Space%
	{
		Word = %A_LoopField%

		; Short circuit if single letter
		if strlen(Word) < 2
		{
			continue
		}

		; Short cut if its properly spelled
		if (Spell_Spell(hSpell, Word))
		{
			continue
		}

		; --- From here we have a new word to check

		; Generate suggestions
 		Spell_Suggest(hSpell, Word, sList)
 		if not sList
		{
			sList = No suggestions
		}

    	; Call GUI for decision - disable current GUI
    	Replacement := MySpellCheckGUI(Word, sList)

    	; Remember the word to avoid re-asking
    	Spell_Add(hSpell,Word)

    	if not Replacement
    	{
    		continue
    	} else {
			; Replace in the original string (whole words)
			sText := RegExReplace(sText,"m)\b" . Word . "\b",Replacement)
    	}

	}

	; Close the Spell GUI
	Gui, 2:Destroy
	Gui, 1:Show

    ; Trim the text padding
    StringTrimLeft, sText, sText, 1
    StringTrimRight, sText, sText, 1

	; Write back the new text
	HE_ReplaceSel(HiEdit1,sText)

	; Release DLL memory
	Spell_Uninit(hSpell)

    ; Clear variables
    sText =
    tText =
    Replacement =
}

MySpellCheckGUI(Word, sList){
	Global
	; Ensure all global variables

	; Clear variables
	Suggestion =

	; Setup the GUI
	Gui, 2:+Owner +ToolWindow +AlwaysOnTop +Delimiter`n
	Gui, 2:Add, Text, 		x7 		y7 		w250 	h21 , %Word% not in dictionary
	Gui, 2:Add, Text, 		x7 		y30 	w250 	h13 , Replace:
	Gui, 2:Add, Edit, 		x7 		y44 	w250 	h21 , %Word%
	Gui, 2:Add, Text, 		x7 		y72 	w250 	h13 , Suggestions:
	Gui, 2:Add, ListBox, 	x7 		y86 	w250 	h102 Choose1 vSuggestion, %sList%

	Gui, 2:Add, Button, 	x265 	y53 	w90 	h23 , &Ignore
	Gui, 2:Add, Button, 	x265 	y86 	w90 	h23 , &Replace
	Gui, 2:Add, Button, 	x265 	y119 	w90 	h23 , A&dd Word
	Gui, 2:Add, Button, 	x265 	y152 	w90 	h23 , Cancel

	; Show child
	Gui, 2:Show, 			x142 	y369 	w363	h193, Spell Check

	; Loop until a decision is made  (GUI cannot be modal and stop a loop)
	NextWord = 0
	Loop,
	{
		if NextWord > 0
		{
			Break
		} else {
			Sleep, 300
			Continue
		}
	}

	; This is Submit
	Gui 2:Destroy
	Gui, 1:show
	Return %Suggestion%

; Gui subroutines
2ButtonIgnore:
    ; Record so we don't ask again
    Spell_Add(hSpell, Word, "L")
	Suggestion = 0
	NextWord = 1
	Return

2ButtonReplace:
	Gui, Submit, NoHide
	if (Suggestion = "No suggestions")
	{
		Suggestion = 0
	}
	NextWord = 1
	Return

; TODO this does not work!!
2ButtonAdd:
;  	Spell_AddCustom(DicPath . "USER_DICT.dic",Word)
	Suggestion = 0
	NextWord = 1
	Return

2ButtonCancel:
2GuiClose:
2GuiEscape:
	Gui, 2:Destroy
	Suggestion = 0
	Return

Exit
}
