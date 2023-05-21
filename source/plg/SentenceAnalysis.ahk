; Sentence Analysis Script

; Setup Toggle Key
;#s::Pause, Toggle

; ***Sentence length
; This simply counts the number of spaces between terminators (.|?|!)
; Update - now up lifts the limit if there are parentheses, commas or hyphens.
; Setup parameters


WordLimit = 20
ParethesisUplift = 5

*~[::
*~]::
*~-::
*~,::
*~(::
*~)::
	EnvAdd, WordLimit, %ParethesisUplift%
return

*~Space::
	WordCount++
	if (WordCount > WordLimit) {
	MsgBox ,1 , Lexia - Sentence too long?, % "This sentence has " WordCount " words. Exceeding the word limit of " WordLimit
	}
return

*~.::
*~?::
*~!::
	if (WordCount > WordLimit) {
	MsgBox ,1 , Lexia - Sentence too long?, % "This sentence has " WordCount " words. Exceeding the word limit of " WordLimit
	}
	WordCount = 0
return

*~Enter::
	WordCount = 0
return
