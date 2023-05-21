; This is my spellcheck plugin for HiEdit
;  as usual much is borrowed for online examples :)
#include inc\Spell.ahk

$SpellCheck(hEdit, sText){

    ; Destroy previous iterations
    Spell_Uninit(hSpell)
    tText =


	; Initialize
	if not Spell_Init(hSpell,"O:\MyProfile\editor\hunspell\en_GB.aff", "O:\MyProfile\editor\hunspell\en_GB.dic","O:\MyProfile\editor\hunspell\Hunspellx86.dll")
		return

	; Load the custom dictionary
	if not Spell_InitCustom(hSpell,"O:\MyProfile\editor\hunspell\user_dict.dic","L")
		return

	; Check for selection
	if Strlen(sText) < 1
	{
		sText := $GetAllText(hEdit)
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
	StringReplace, tText, tText, |, %A_Space% , All
	StringReplace, tText, tText, \, %A_Space% , All
	StringReplace, tText, tText, /, %A_Space% , All
	StringReplace, tText, tText, ", %A_Space% , All
; 	StringReplace, tText, tText, ', %A_Space% , All
	StringReplace, tText, tText, :, %A_Space% , All
	StringReplace, tText, tText, %A_Space%-%A_Space%, %A_Space% , All
	StringReplace, tText, tText, %A_Space%%A_Space%, %A_Space% , All
	StringReplace, tText, tText, %A_Space%%A_Space%, %A_Space% , All
	StringReplace, tText, tText, %A_Space%%A_Space%, %A_Space% , All

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

		; Launch the GUI
		Spell_Suggest(hSpell, Word, sList)
		Replacement := $SpellCheckGUI(hEdit, Word, sList)

		; Use the Replacement
		if (Replacement<>0)
		{
			; Replace in the original string
			StringReplace, sText, sText, %A_Space%%Word%%A_Space%, %A_Space%%Replacement%%A_Space%, All

			; Record so we don't ask again
			; Spell_Add(hSpell, Word, "L")
		}

        ; Clear variables
        Word =
        Replacement =
        sList =

	}

	; Close the Spell GUI
	Gui, 2:Destroy
	Gui, 1:Show

    ; Trim the text padding
    StringTrimLeft, sText, sText, 1
    StringTrimRight, sText, sText, 1

	; Write back the new text
	HE_ReplaceSel(hEdit,sText)

	; Release DLL memory
	Spell_Uninit(hSpell)

    ; Clear variables
    sText =
    tText =

	Return
}


$SpellCheckGUI(hEdit, Word, sList){
	Global
	; Ensure all global variables

	Suggestion =

	if not sList
	{
		sList = "No suggestions"
	}

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

	; Loop until a selection is made  (GUI cannot be modal and stop a loop)
	Loop,
	{
		if %hEdit%%Word%
		{
			Break
		} else {
			Sleep, 300
			Continue
		}
	}

	; This is Submit
	Gui 2:Destroy
	Return %Suggestion%

; Gui subroutines
2ButtonIgnore:
	%hEdit%%Word% = %Word%
	Suggestion = 0
	Return

2ButtonReplace:
	Gui, Submit, NoHide
	%hEdit%%Word% = %Suggestion%
	Return

2ButtonAdd:
; 	Spell_AddCustom("O:\MyProfile\editor\hunspell\user.dic",Word)
	%hEdit%%Word% = %Word%
	Suggestion = 0
	Return

2ButtonCancel:
2GuiClose:
2GuiEscape:
	Gui, 2:Destroy
	Gui, 1:-0x8000000 ; 0x8000000 is WS_DISABLED
	Gui, 1:show
	Suggestion = 0
	Return
 	Exit
}


