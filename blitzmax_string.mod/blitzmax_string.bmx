' ------------------------------------------------------------------------------
' -- sodaware.blitzmax_string
' --
' -- Helper functions for working with strings.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2017 Phil Newton
' --
' -- This library is free software; you can redistribute it and/or modify
' -- it under the terms of the GNU Lesser General Public License as
' -- published by the Free Software Foundation; either version 3 of the
' -- License, or (at your option) any later version.
' --
' -- This library is distributed in the hope that it will be useful,
' -- but WITHOUT ANY WARRANTY; without even the implied warranty of
' -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' -- GNU Lesser General Public License for more details.
' --
' -- You should have received a copy of the GNU Lesser General Public
' -- License along with this library (see the file LICENSE for more
' -- details); If not, see <http://www.gnu.org/licenses/>.
' ------------------------------------------------------------------------------


SuperStrict

Module sodaware.blitzmax_string

''' <summary>Check if a string is a number.</summary>
''' <param name="value">The string to check.</param>
''' <return>True if string is numeric, false if not.</return>
Function IsNumeric:Byte(value:String)
	For Local pos:Int = 0 To value.Length - 1
		Local char:Byte = value[pos]
		If (char < 48 or char > 57) And (char < 43 or char > 46) Then
			Return False
		End If
	Next
	Return True
End Function

''' <summary>Works like standard split, but does not split text in quotes.</summary>
Function SplitQuotedString:String[](text:String, delimiter:String = ",")
	Local pieces:String[]         = New String[1]
	Local piecesPos:Int           = 0
	Local stringPos:Int           = 0
	Local inQuotes:Byte           = False
	Local currentQuoteChar:String = ""
	Local str2:String             = ""
	Local skipChar:Byte           = False

	Repeat
		' Get the current character.
		Local currentChar:String = Chr(text[stringPos])
		skipChar = False

		' Check if in a quoted string.
		If currentChar = "~q" Or currentChar = "'" Then
			' Check if we're counting this character.
			If inQuotes = True And currentChar = currentQuoteChar Then
				inQuotes = Not(inQuotes)
				skipChar = True
			ElseIf inQuotes = False Then
				' Setup the current quote character (so we can use quotations inside the string).
				currentQuoteChar = currentChar
				inQuotes = True
				skipChar = True
			End If
		End If

		' Split at location, unless in a quoted string.
		If currentChar = delimiter Then
			If inQuotes = True Then str2:+ currentChar
		Else
			If Not(skipChar) Then str2:+ currentChar
		End If

		If currentChar = delimiter Or stringPos = text.Length - 1 Then
			If inQuotes = False Then
				pieces[piecesPos] = str2.Trim()
				str2 = ""
				piecesPos:+ 1
				pieces = pieces[..piecesPos + 1]
			End If
		End If

		stringPos:+ 1

		If stringPos = text.Length Then Exit
	Forever

	If pieces.Length > 1 Then pieces = pieces[..pieces.Length - 1]

	Return pieces
End Function
