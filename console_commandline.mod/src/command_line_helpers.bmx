' ------------------------------------------------------------------------------
' -- src/command_line_helpers.bmx
' --
' -- Internal utility functions used by the command line options type. Lives in
' -- a separate type so that inherited option classes don't contain a lot of 
' -- unnecessary functions.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Private

Type CommandLineHelpers

	Const VALID_CHARS:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789?"	
	
	''' <summary>Gets the position of an option within an option string.</summary>
	''' <remarks>Used to get an option name regardless of short, long or forward-slash syntax.</remarks>
	''' <param name="opt">The option string to search.</param>
	''' <param name="allowForwardSlash">If true, will allow Windows forward slash syntax.</param>
	''' <returns>The position of the option name within the passed string.</returns>
	Function GetOptionNamePosition:Int(opt:String, allowForwardSlash:Int)
		
		If opt.Length < 2		' Not an option
			Return 0
		Else If opt.Length > 2	' Not a short option, is it a long one?
			
			' Could be a long option
			If Chr(opt[0]) = "-" And Chr(opt[1]) = "-" And CommandLineHelpers.IsValidChar(Chr(opt[2])) Then
				Return 2
			
			' Short option
			ElseIf Chr(opt[0]) = "-" And CommandLineHelpers.IsValidChar(Chr(opt[1])) Then
				Return 1
				
			' Windows forward-slash syntax
			ElseIf ((Chr(opt[0]) = "/") And allowForwardSlash) And CommandLineHelpers.IsValidChar(Chr(opt[1]))
				Return 1
			End If
		Else					' Could be a short option
			If (Chr(opt[0]) = "-" Or (Chr(opt[0]) = "/" And allowForwardSlash)) And CommandLineHelpers.IsValidChar(Chr(opt[1])) Then Return 1
		End If
		
		Return 0

	End Function
	
	''' <summary>Parses a Blitz meta field into a map of key => value pairs.</summary>
	Function ParseMetaString:TMap(meta:String)
		
		Local metaData:TMap	      = New TMap
		
		Local currentField:String = ""
		Local currentValue:String = ""
		Local inString:Int        = False
		Local isField:Int         = True
		
		For Local pos:Int = 0 To meta.Length
			
			Local currentChar:String = Mid(meta, pos, 1) 'Chr(meta[pos])
			
			Select currentChar
				
				Case "="
					If Not(inString) Then isField = Not(isField)
					
				Case "~q"
					inString = Not(inString)
					
				Case " "
					' If not in a string, we're at the end of a field
					If inString = False Then
						metaData.Insert(currentField, currentValue)
						currentField = ""
						currentValue = ""
						isField = True
					Else
						If isField Then 
							currentField:+ currentChar	
						Else 
							currentValue:+ currentChar	
						End If
					End If
					
				Default
				
					' No special character - add to field name / value
					If isField Then 
						currentField:+ currentChar	
					Else 
						currentValue:+ currentChar	
					End If
					
			End Select
			
		Next
		
		' Add last field
		If currentField <> " " And currentField <> "" And isField = False Then
			metaData.Insert(currentField, currentValue)
		EndIf
			
		Return metaData
		
	End Function
	
	Function WrapText:String(text:String, wrapWidth:Int, columnWidth:Int)
		
		Local words:String[] = text.Split(" ")
		Local output:String	 = ""
		Local currentLine:String = ""
		
		For Local word:String = EachIn words
			
			' Check if line is too long
			If (currentLine.Length + wrapWidth + word.Length) > columnWidth Then
				output = currentLine + "~n"
				currentLine = RSet("", wrapWidth + 1)
			EndIf
		
			currentLine = currentLine + word + " " 
			
		Next

		output = output + currentLine
		Return output
			
	End Function
	
	' -- Checks to see if a character can appear as an option name
	Function IsValidChar:Int(char:String)	' TODO: Change invalid char length to an exception?
		Return (char.Length = 1 & (CommandLineHelpers.VALID_CHARS.Find(char, 0) <> - 1))		
	End Function

	' Gets the option name from an option string
	'  e.g. "--option=value" will return "--option"
	Function GetOptionName:String(optionString:String)
		
		' No seperator found - return just the option name
		Local pos:Int	= GetSeparatorPos(optionString)
		If pos = -1 Then Return optionString		
		
		Return Left(optionString, pos)
		
	End Function

	' -- Gets the value of an option from an option string
	Function GetOptionValue:String(optionString:String)
		
		' If no seperator found???
		Local pos:Int	= GetSeparatorPos(optionString)
		If pos = -1 Then Return ""
		
		Return Right(optionString, optionString.Length - pos - 1)
		
	End Function 
	
	' -- Gets the position of a separator (= or :) in an option string.
	Function GetSeparatorPos:Int(optionString:String)
		Local pos:Int	= optionString.Find("=")
		If pos = -1 Then pos = optionString.Find(":")
		
		Return pos
	End Function

End Type

Public