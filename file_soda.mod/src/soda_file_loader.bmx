' ------------------------------------------------------------
' -- src/soda_file_loader.bmx
' -- 
' -- Load SodaFiles.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Type SodaFile_Loader
	
	Global CHAR_LOOKUP:String[256]
	
	Field _pos:Int          = 0
	Field _buffer:String    = ""
	
	
	' ------------------------------------------------------------
	' -- Load functions
	' ------------------------------------------------------------
	
	Function Load:SodaFile(url:Object)
	
		' Load from either a stream, or if this fails, any other supported object.
		Local loader:SodaFile_Loader = New SodaFile_Loader
		Local result:SodaFile        = New SodaFile
		Local fileIn:TStream  	     = ReadFile(url)
		
		If fileIn <> Null Then
			loader.loadFromStream(fileIn, result)
			fileIn.Close()
		Else

			' TODO: Allow loading from objects, banks and uri's
			Local streamType:TTypeId = TTypeId.ForObject(url)
			If streamType = Null Then Throw "Unable to load SodaFile: " + url.toString()
			
			Select streamType.Name().ToLower()
				Case "string"
					loader.loadFromString(String(url), result)
					' TODO: Don't query internals. It's bad.
					If result._groups.Count() = 0 Then result = Null
			End Select
		
		EndIf
				
		Return result
		
	End Function
	
	Method loadFromString:SodaFile(in:String, result:SodaFile)
		Local data:TBank	= TBank.Create(in.Length)
		For Local char:Int = 0 To in.Length - 1
			data.PokeByte(char, in[char])
		Next
		Self.LoadFromStream(ReadStream(data), result)
		data = Null
		Return result
	End Method
		
	Method loadFromStream:SodaFile(fileIn:TStream, result:SodaFile)
		
		' [todo] - Throw a file exception here so it can be caught
		If fileIn = Null Then Throw "Attempted to read from null stream"
		
		While Not(fileIn.Eof())
			Self.findGroupStart(fileIn)
			Local new_group:SodaGroup = Self.readGroup(fileIn, result)
			result.addGroup(new_group)
		Wend
		
	End Method
	
	''' <summary>
	''' Reads the entire contents of a stream and returns it as a string.
	''' </summary>
	Function readAll:String(file:TStream)
		
		Local contents:String = ""
		While Not(file.Eof())
			contents:+ file.ReadLine() + "~n"
		Wend
		
		' Add a terminator
		contents:+ "~0"
		Return contents
		
	End Function
	

	
	
	' ------------------------------------------------------------
	' -- Reading Elements
	' ------------------------------------------------------------
	
	''' <summary>Reads a group from a file stream.</summary>
	Method readGroup:SodaGroup(fileIn:TStream, result:SodaFile)
		
		Local group:SodaGroup	= New SodaGroup
		
		Local char:Byte
		Local nextChar:Byte
		Local oldChar:Byte
		
		Local currentField:String	= ""
		Local currentValue:String	= ""
		Local inField:Int			= True
		Local fieldCount:Int		= 0
		Local inString:Int 			= False
		Local isArray:Int			= False
		
		While Not(fileIn.Eof())
		
			oldChar	= char
			char	= fileIn.ReadByte()
			
			' todo: would be nice not to do this
			If fileIn.Pos() < fileIn.Size() Then
				nextChar = fileIn.ReadByte()
				fileIn.Seek(fileIn.Pos() - 1)
			EndIf

			
			' Action depends on character:
			
			' [ = start group id
			' ]	= end group id
			
			' { = start group
			' } = end group
		
			' ; = new line
			' " = start / end string
			' = = Assignment operator
			' * = array modifier (i.e. entity is array)
			
			' Tokens:
			' [[	= script start
			' ]]	= script end
			' //	= Ignore rest of line
			' /*	= multi-line comment start
			' */	= multi-line comment end
			
			Select char
				
				' -- Start of a group identifier
				Case ASC_SQUARE_OPEN
					If inString Then
						currentValue:+ SodaFile_Loader.CHAR_LOOKUP[char]
					Else
						
						' Script source ([[ ]])
						If nextChar = ASC_SQUARE_OPEN Then 
							currentValue = Self.readScriptSource(fileIn)
						Else
							If group.Identifier = "" Then 
								Self.readGroupIdentifier(fileIn, group)
							Else
								fileIn.Seek(fileIn.Pos() - 1)
								group.addChild(Self.readGroup(fileIn, result))
							EndIf
						EndIf
					
					EndIf
						
				' -- Comment start
				Case ASC_FORWARD_SLASH 
				
					' TODO: Fix the bug here for "/*" inside a string
					If inString = False And oldChar = ASC_FORWARD_SLASH Then

						Self.collapseSingleComment(fileIn)
						oldChar = 0
						char = 0
					Else
						If Not( inField ) Then currentValue:+ SodaFile_Loader.CHAR_LOOKUP[char]
					EndIf
				
				' -- Array notification OR potential comment end
				Case ASC_ASTERISK
					
					If inString Then
						currentValue:+ "*"
					ElseIf oldChar = ASC_FORWARD_SLASH Then

						Self.collapseMultiComment(fileIn)

					Else 
						If inField Then
							isArray = True
						Else
							currentValue:+ "*"
						EndIf
						' If inField then currentFieldIsArray = true
						'  When adding field, be sure to set it as an array - this will change ALL of the get method code :( , but use current tests to make sure they don't break shit :) 
'						Print "ARRAY!"
					EndIf
					
				' -- End of declaration
				Case ASC_SEMI_COLON
				
					' Clean up data
					currentField = currentField.Trim()
					currentValue = currentValue.Trim()
					
					If currentField.Contains(":") Then
						
						' Shorthand syntax
						Local groupName:String = Left(currentField, currentField.Find(":"))
						Local fieldName:String = Right(currentField, currentField.Length - currentField.Find(":") - 1)
						
						' Find the this belongs to group
						Local shorthandGroup:SodaGroup
						
						If group <> Null Then
							shorthandGroup = group.GetChild(groupName)
						Else
							shorthandGroup:SodaGroup = result.GetGroup(groupName)
						EndIf
						
						If shorthandGroup = Null Then
							shorthandGroup = New SodaGroup
							shorthandGroup.SetIdentifier(groupName)
							
							If group <> Null Then
								group.AddChild(shorthandGroup)
							Else
								result.addGroup(shorthandGroup)
							EndIf
						EndIf
						
						shorthandGroup.AddField(fieldName, currentValue, isArray)
						
					Else 
						group.AddField(currentField, currentValue, isArray)
					End If
					inField = True
					inString = False
					currentfield = ""
					currentValue = ""
					isArray = False
					
				' Assignment - switch to value
				Case ASC_EQUALS
					inField = False
				
				' New line
				Case ASC_LF
					Self.collapseWhitespace(fileIn)
				
				' -- Quote - used in a string
				Case ASC_QUOTE
					If oldChar <> ASC_BACKSLASH Then 
						inString = Not(inString)
					Else 
						If inField Then
							currentField:+ SodaFile_Loader.CHAR_LOOKUP[char]
						Else
							currentValue:+ SodaFile_Loader.CHAR_LOOKUP[char]
						EndIf
					EndIf
				
				' Start of a group (absorbed in GetGroupIdentifier)	
				Case ASC_CURLY_OPEN
					If inField = False Or inString Then currentValue:+ SodaFile_Loader.CHAR_LOOKUP[char]
					
				' Group terminator
				Case ASC_CURLY_CLOSE
				
					' [todo] - If the current line has not been terminated, should throw an error here!
				
					If inString Then 
						currentValue:+ SodaFile_Loader.CHAR_LOOKUP[char]
					Else 
						Return group
					EndIf
						
				' Any other char - add to fieldName or fieldValue
				Default;
					If char > 31 Then 
						If inField Then
							currentField:+ SodaFile_Loader.CHAR_LOOKUP[char]
						Else
							currentValue:+ SodaFile_Loader.CHAR_LOOKUP[char] 'token:+ char
						EndIf
					EndIf
						
			End Select
			
		Wend			 
		
		Return Null
	
	End Method
	
	''' <summary>Finds the start of a group.</summary>
	Method findGroupStart(fileIn:TStream)
		
		Local char:Byte
		Local oldChar:Byte
		
		While Not(fileIn.Eof())
			oldChar	= char
			char	= fileIn.ReadByte()
			
			Select char
				
				' Start of group
				Case ASC_SQUARE_OPEN
					' remove this!!
					fileIn.Seek(fileIn.Pos() - 1)
					Return
				
				' Comments
				Case ASC_FORWARD_SLASH
					If oldChar = ASC_FORWARD_SLASH Then Self.collapseSingleComment(fileIn)
					
				Case ASC_ASTERISK
					If oldChar = ASC_FORWARD_SLASH Then Self.collapseMultiComment(fileIn)
					
			End Select
			
		Wend
		
	End Method
	
	''' <summary>Reads the identifier for a group from a stream.</summary>
	Method readGroupIdentifier(fileIn:TStream, group:SodaGroup)
		
		Local name:String
		Local charIn:Byte
		
		Repeat
			If fileIn = Null Or fileIn.Eof() Then Exit
			charIn = fileIn.ReadByte()
			If charIn <> ASC_SQUARE_CLOSE Then
				name:+ SodaFile_Loader.CHAR_LOOKUP[charIn]
			EndIf
		Until charIn = ASC_SQUARE_CLOSE ' = "]"
		
		' Check if this group is an array
		If name.EndsWith("*") Then
			group._isArray = True
			name = name.Replace("*", "")
		End If
		
		group.setIdentifier(name)
		
	End Method
	
	''' <summary>Reads the source of a script.</summary>
	Method readScriptSource:String(fileIn:TStream)
		
		' Skip first char ([)
		fileIn.ReadByte() 
		
		Local char:Byte
		Local oldChar:Byte
		Local script:String = ""
		
		While Not(fileIn.Eof())
		
			oldChar = char
			char	= fileIn.ReadByte()
			
			If char = ASC_SQUARE_CLOSE And oldChar = ASC_SQUARE_CLOSE Then
				script = Left(script, script.Length - 1)
				Return script
			Else
				script:+ SodaFile_Loader.CHAR_LOOKUP[char]
			End If
		Wend
	
		Return script
		
	End Method

	Method ReadString:String(fileIn:TStream)
		
		Local char:Byte
		Local oldChar:Byte
		Local txt:String = ""
		
		While Not(fileIn.Eof())
			oldChar = char
			char	= fileIn.ReadByte()
			
			If char = ASC_QUOTE And oldChar <> ASC_BACKSLASH Then 
				Return txt
			Else
				txt:+ SodaFile_Loader.CHAR_LOOKUP[char]
			End If
		Wend
		
		Return txt
		
	End Method
	
	
	' ------------------------------------------------------------
	' -- Collapse methods
	' ------------------------------------------------------------
	
	Method collapseWhitespace(fileIn:TStream)
		While Not(fileIn.Eof()) And fileIn.ReadByte() < 31
		Wend
		fileIn.Seek(fileIn.Pos() - 1)
	End Method
	
	Method collapseSingleComment(fileIn:TStream)
		While Not(fileIn.Eof()) And fileIn.ReadByte() <> ASC_LF	
		Wend
	End Method
	
	Method collapseMultiComment(fileIn:TStream)
		
		Local char:Byte
		Local oldChar:Byte
		
		While Not(fileIn.Eof())
			
			oldChar	= char			
			char 	= fileIn.ReadByte()
			
			If oldChar = ASC_ASTERISK And char = ASC_FORWARD_SLASH Then Exit
			
		Wend
		
		fileIn.Seek(fileIn.Pos() - 1)
		
	End Method
		
End Type


Private

SodaFile_Loader.CHAR_LOOKUP = New String[256]

For Local i:Int = 0 To 255
	SodaFile_Loader.CHAR_LOOKUP[i] = Chr(i)
Next

Public
