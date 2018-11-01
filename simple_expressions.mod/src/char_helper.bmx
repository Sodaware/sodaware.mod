' ------------------------------------------------------------------------------
' -- src/char_helper.bmx
' --
' -- Helper functions working with characters. Used by the expression parser.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2018 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Type CharHelper

	' ------------------------------------------------------------
	' -- Character Functions
	' ------------------------------------------------------------

	Function IsLetterOrDigit:Byte(character:String)
		Return CharHelper.IsLetter(character) Or CharHelper.isdigit(character)
	End Function

	Function IsWhitespace:Byte(character:String)
		Return ( Asc(character) < 33 Or Asc(character) >= 127 Or character = "" )
	End Function

	Function IsDigit:Byte(character:String)
		Return ( Asc(character) >= 48 And Asc(character) =< 57 )
	End Function

	Function IsLetter:Int(character:String)
		Local charValue:Byte = Asc(character)
		Return (charValue >= 65 And charValue <= 90) Or (charValue >= 97 And charValue =< 122)
	End Function


	' ------------------------------------------------------------
	' -- ASCII Functions
	' ------------------------------------------------------------

	Function IsAsciiLetterOrDigit:Byte(character:Byte)
		Return CharHelper.IsAsciiLetter(character) Or CharHelper.IsAsciiDigit(character)
	End Function

	Function IsAsciiWhitespace:Byte(character:Byte)
		' TODO: >= 127 is not whitespace
		Return (character < 33 Or character >= 127)
	End Function

	Function IsAsciiDigit:Byte(character:Byte)
		Return character >= 48 And character =< 57
	End Function

	Function IsAsciiLetter:Int(character:Byte)
		Return (character >= 65 And character <= 90) Or (character >= 97 And character =< 122)
	End Function

End Type
