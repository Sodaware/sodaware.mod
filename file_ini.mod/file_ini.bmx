' ------------------------------------------------------------------------------
' -- sodaware.file_ini
' --
' -- Library for working with ini files.
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

Module sodaware.file_ini

Import sodaware.blitzmax_ascii
Import brl.filesystem

Import "src/ini_file.bmx"

Type File_INI

	Function LoadFile:IniFile(url:Object)

		' Don't load if the stream is invalid.
		Local fileIn:TStream = ReadFile(url)
		If fileIn = Null Then Return Null

		' Read each line of the file
		Local result:IniFile = New IniFile
		Local line:String
		Local currentPair:String[]
		Local currentSection:String = ""

		While Not fileIn.Eof()
			' Read each line and clean it up.
			line = fileIn.ReadLine()
			line = File_INI._CleanLine(line)

			' Skip empty lines.
			If line = "" Then Continue

			' If line is a section start, get the section name and add it
			If line.StartsWith("[") And line.EndsWith("]") Then
				currentSection = line[1 .. line.Length - 1]
				result.addSection(currentSection)
			ElseIf currentSection
				' If in a section, add the key/value
				currentPair = File_INI._ExtractKeyVales(line)
				result.set(currentSection, currentPair[0], currentPair[1])
			End If
		Wend

		fileIn.Close()

		Return result

	End Function

	''' <summary>Save an IniFile to a file or stream.</summary>
	''' <param name="url">The filename or stream to save to.</param>
	''' <param name="ini">The ini file to save.</param>
	Function Save(url:Object, ini:IniFile)
		Local fileOut:TStream = WriteStream(url)

		If fileOut Then
			fileOut.WriteString(ini.toString())
			fileOut.Close()
		End If
	End Function


	' ------------------------------------------------------------
	' -- Internal Helpers
	' ------------------------------------------------------------

	''' <summary>Strip all whitespace from a line.
	Function _CleanLine:String(line:String)
		line = line.Trim()

		' Strip anything after the comments off.
		Local cleanedLine:String = ""
		Local currentChar:Byte   = 0
		Local inString:Byte      = False

		For Local i:Int = 0 To line.Length - 1
			currentChar = line[i]

			If currentChar = ASC_QUOTE Then inString = Not(inString)
			If Not(inString) And (currentChar = ASC_SEMI_COLON Or currentChar = ASC_HASH) Then Exit

			cleanedLine :+ Chr(currentChar)
		Next

		Return cleanedLine.Trim()
	End Function

	Function _ExtractKeyVales:String[](line:String)
		If line = Null Then Return Null

		Local keyName:String   = ""
		Local keyValue:String  = ""
		Local currentChar:Byte = 0
		Local inString:Byte    = False
		Local inValue:Byte     = False

		For Local i:Int = 0 To line.Length - 1
			currentChar = line[i]
			If currentChar = ASC_QUOTE Then inString = Not(inString)

			' If an `=` is found, move to the key name.
			If currentChar = ASC_EQUALS And Not(inString) Then
				inValue = True
				Continue
			EndIf

			If inValue Then
				keyValue :+ Chr(currentChar)
			Else
				keyName :+ Chr(currentChar)
			End If
		Next

		Return [keyName.Trim(), keyValue.Trim()]
	End Function

End Type
