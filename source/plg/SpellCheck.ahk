; This is my spellcheck plugin for HiEdit
#include inc\Spell.ahk

$SpellCheck(hEdit, sText){
	; Check for selection
	If Strlen(sText) < 1
	{
		sText := $GetAllText(hEdit)
	}
	If Strlen(sText) < 1
	{
		; This is an empty file
		msgbox, No text to spellcheck
		return
	}

	;-- Initialize
	if not Spell_Init(hSpell,"O:\MyProfile\editor\hunspell\en_GB.aff", "O:\MyProfile\editor\hunspell\en_GB.dic","O:\MyProfile\editor\hunspell\Hunspellx86.dll")
    	return
	
	;-- Load the custom dictionary
	Spell_InitCustom(hSpell,"O:\MyProfile\editor\hunspell\user_dict.dic","L")

	; Parse for words in sText pausing for each miss - spellings
	; Init file pointer
	fp = 1
	Loop
	{
		; Seach fornext word
		fp := RegExMatch(sText, "i)\w\w*'*\w*" , Word, fp)

		; Check found word is > 1 char (This could be part of the RE?)
		If strlen(Word) >1
		{
			fp := fp + strlen(Word)
		} Else {
			fp++
			Continue ; Short circuit if single letter
		}

		; Check for end of selection
		If (fp =0 or fp >= (strlen(sText)))
		{
			Break
		}



		; Check against our dictionary if its a word we haven't seen before
		If (Spell_Spell(hSpell, Word))
		{
			; No replacement necessary
			; Make entry in our index
			Spell_add(hSpell, Word, "L")
			continue
		} Else {
			Spell_Suggest(hSpell, Word, sList)
		}

		; Activate/reload Spell check GUI
		Gui 2:Destroy
		NewWord := $SpellCheckGUI(hEdit, Word, sList)

		; Replace if necessary ** Needs to do whole word replacment not part word
		If (NewWord<>0)
		{
			StringReplace, sText, sText, %Word%, %NewWord%
			fp := fp + (strlen(NewWord) - strlen(Word))
		}
	}
	; Clear up ***
	fp = 1

	; Release DLL memory
	Spell_Uninit(hSpell)

	; Close the Spell GUI
	Gui, 2:Destroy
	Gui, 1:-0x8000000 ; 0x8000000 is WS_DISABLED
	Gui, 1:Show

	; Write back the new text
	HE_ReplaceSel(hEdit,sText)
	Return
	Exit
}


$SpellCheckGUI(hEdit, Word, sList){
	Global
	; Ensure all global variables

	Suggestion =

	If sList
	{

	}Else {
		sList = "No suggestions"
	}

	; Setup the GUI
	Gui, 2:+Owner +ToolWindow +AlwaysOnTop +Delimiter`n
	Gui, 2:Add, Text, 	x7 		y7 		w250 	h21 , %Word% not in dictionary
	Gui, 2:Add, Text, 	x7 		y30 	w250 	h13 , Replace with:
	Gui, 2:Add, Edit, 		x7 		y44 	w250 	h21 , %Word%
	Gui, 2:Add, Text, 	x7 		y72 	w250 	h13 , Suggestions:
	Gui, 2:Add, ListBox, 	x7 		y86 	w250 	h102 Choose1 vSuggestion, %sList%

	Gui, 2:Add, Button, 	x265 	y53 	w90 	h23 , &Ignore
	Gui, 2:Add, Button, 	x265 	y86 	w90 	h23 , &Replace
	Gui, 2:Add, Button, 	x265 	y119 	w90 	h23 , A&dd Word
	Gui, 2:Add, Button, 	x265 	y152 	w90 	h23 , Cancel

	; Show child and Dissable parent
	Gui, 2:Show, 			x142 	y369 	w363	h193, Spell Check
	Gui, 1:+0x8000000 ; 0x8000000 is WS_DISABLED

	; Loop until a selection is made  (GUI cannot be modal and stop a loop)
	Loop,
	{
		If %hEdit%%Word%
		{
			Break
		} Else {
			Sleep, 300
			Continue
		}
	}

	Gui 2:Destroy
	Return %Suggestion%

; Function subroutines
2ButtonIgnore:
	%hEdit%%Word% = %Word%
	Suggestion = 0
	Return

2ButtonReplace:
	Gui, Submit, NoHide
	%hEdit%%Word% = %Suggestion%
	Return

2ButtonAdd:
; 	%hEdit%%Word% = %Word%
; 	Spell_AddCustomWord("O:\MyProfile\editor\hunspell\user.dic",Word)
; 	Suggestion = 0
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

