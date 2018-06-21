' ------------------------------------------------------------------------------
' -- sodaware.console_rainbow
' --
' -- Add some colour to console text.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2018 Phil Newton
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


Module sodaware.console_rainbow

SuperStrict

Import brl.retro

Global Console_Rainbow_Pattern:String = "RyYGBMP"

''' <summary>Adds rainbow colour codes to a string. Use with `console_color` module to display.</summary>
''' <param name="text">The text to convert.</param>
''' <param name="pattern">Optional colour code pattern to use. Defaults to `Console_Rainbow_Pattern` value if empty.</param>
''' <return>String with colour codes added.</return>
Function Console_Rainbow:String(text:String, pattern:String = "")
	If pattern = "" Then pattern = Console_Rainbow_Pattern

	Local rainbow:String = ""
	Local colourPos:Int  = 0
	Local maxColours:Int = pattern.Length
	Local textLength:Int = text.Length

	For Local i:Int = 1 To textLength
		rainbow :+ "%" + Mid(pattern, colourPos + 1, 1)
		rainbow :+ Mid(text, i, 1)
		colourPos :+ 1
		If colourPos >= maxColours Then colourPos = 0
	Next

	Return rainbow + "%n"
End Function
