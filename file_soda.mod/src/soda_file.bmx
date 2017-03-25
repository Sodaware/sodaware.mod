' ------------------------------------------------------------
' -- src/soda_file.bmx
' -- 
' -- Type that represents a single SODA file. A SODA file is made up of fields
' -- and groups.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

' TODO: Lots of refactoring to do

Import brl.linkedlist
Import brl.filesystem
Import brl.stream
Import brl.map
Import brl.bank
Import brl.retro
Import brl.reflection

Import sodaware.blitzmax_ascii

Import "soda_file_util.bmx"
Import "soda_group.bmx"


Type SodaFile
	
	Global CHAR_LOOKUP:String[256]
	
	Field _pos:Int          = 0
	Field _buffer:String    = ""
	Field _groups:TList     = New TList		'''< Internal list of of groups in this file
	Field _queryCache:TMAP  = New TMAP		'''< Internal cache of query results
	
	' TODO: Replace _groups with an objectbag?
	
	' ------------------------------------------------------------
	' -- Helper Functions
	' ------------------------------------------------------------
	
	''' <summary>Get all top-level groups in the SodaFile document.</summary>
	''' <returns>TList of SodaGroup objects.</returns>
	Method getGroups:TList()
		Return Self._groups
	End Method
	
	
	' ------------------------------------------------------------
	' -- Query Helpers
	' ------------------------------------------------------------
	
	''' <summary>Get the boolean value of a query</summary>
	Method queryBool:Int(qry:String)
		Local val:String = String(Self.Query(qry))
		If Int(val) >= 1 Then Return True
		Return (Lower(val) = "true") 
	End Method
	
	''' <summary>Get the integer value of a query.</summary>
	Method queryInt:Int(qry:String)
		Local val:String = String(Self.Query(qry))
		Return Int(val.ToString())
	End Method

	Method queryFloat:Float(qry:String)
		Local val:String = String(Self.Query(qry))
		Return Float(val.ToString())
	End Method
	
	Method queryString:String(query:String)
		Return String(Self.query(query))
	End Method
	
	
	' ------------------------------------------------------------
	' -- Query Functions
	' ------------------------------------------------------------
	
	''' <summary>Gets a group, or the value of a field.</summary>
	Method query:Object(qry:String)
		
		' Check inputs & cache
		If qry = "" Then Return Null
		If Self._queryCache.ValueForKey(qry) <> Null Then 
			Return Self._queryCache.ValueForKey(qry)
		EndIf
		
		' Split into chunks
		Local identifiers:String[] = qry.Split(".")
		Local rootGroup:SodaGroup	= Self.GetGroup(SodaFile_Util.GetName(identifiers[0]), SodaFile_Util.GetOffset(identifiers[0]))
		
		' Check a valid base group was found
		If rootGroup = Null Then Return Null
		
		' Found, so store in cache
		Local value:Object	= rootGroup.Query(SodaFile_Util.AssembleQuery(identifiers))
		Self._queryCache.Insert(qry, value)
		Return value
		
	End Method
	
	' TODO: Can this be made better?
	Method getNodes:TList(qry:String)
		
		Local nodes:TList
	
		If qry.Contains("[") Then
			
			Local conditions:TMAP = New TMap
			
			' Get key/value pairs
			qry = Mid(qry, 2, qry.Length - 2)
			
			' Field name contains meta data
			Local fields:String[] = qry.Split(",")
		
			' Go through fields, splitting into names / meta
			For Local fieldPair:String = EachIn fields
				Local pairs:String[] = fieldPair.Split(":")
				conditions.Insert(pairs[0].ToLower().Trim(), pairs[1].Trim())
			Next
			
			' Evaluate every node
			For Local group:SodaGroup = EachIn Self._groups
				
				Local validKey:Int = True
				For Local key:String = EachIn conditions.Keys()
					If group.GetMeta(key) <> String(conditions.ValueForKey(key)) Then
						validKey = False
						Exit
					EndIf
				Next
				
				If validKey Then
					If nodes = Null Then nodes = New TList
					nodes.AddLast(group)
				EndIf
				
			Next
			
		End If
		
		Return nodes
		
	End Method
	
	Method getGroup:SodaGroup(name:String, offset:Int = -1)
		
		Local currentOffset:Int = 0
	
		For Local group:SodaGroup = EachIn Self._groups
			If group.Identifier = name Then 
				If group._isArray Then
					If offset > -1 And currentOffset = offset Then 
						Return group
					Else
						currentOffset:+ 1
					EndIf
					
				Else
					Return group
				End If
			EndIf
		Next
		
	End Method
	
	
	Function _getGroupName:String(path:String)
		Local names:String[] = path.Split(".")
		Local name:String    = ""
		For Local i:Int = 0 To names.Length - 2
			name:+ names[i] + "."
		Next
		
		' Strip last . and return
		Return Left(name, name.Length - 1)
	End Function

	Function _getFieldName:String(path:String)
		Local names:String[] = path.Split(".")
		Return names[names.Length - 1]
	End Function
	
	
	' ------------------------------------------------------------
	' -- Load functions
	' ------------------------------------------------------------
	
	Function Load:SodaFile(url:Object)

		'Load from either a stream, or if this fails, any other supported object 
		Local this:SodaFile	  	= New SodaFile
		Local fileIn:TStream  	= ReadFile(url)
		
		If fileIn <> Null Then
			this.loadFromStream(fileIn)
			fileIn.Close()
		Else

			' TODO: Allow loading from objects, banks and uri's
			Local streamType:TTypeId = TTypeId.ForObject(url)
			If streamType = Null Then Throw "Unable to load SodaFile: " + url.toString()
			
			Select streamType.Name().ToLower()
				Case "string"	;	 this.LoadFromString(String(url)) ; If this._groups.Count() = 0 Then this = Null
			End Select
		
		EndIf
				
		Return this
	End Function
	
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
	
	Method loadFromString(in:String)
		Local data:TBank	= TBank.Create(in.Length)
		For Local char:Int = 0 To in.Length - 1
			data.PokeByte(char, in[char])
		Next
		Self.LoadFromStream(ReadStream(data))
		data = Null
	End Method
		
	Method loadFromStream(fileIn:TStream)
		
		' [todo] - Throw a file exception here so it can be caught
		If fileIn = Null Then Throw "Attempted to read from null stream"
		
		While Not(fileIn.Eof())
			Self.findGroupStart(fileIn)
			Local new_group:SodaGroup = Self.readGroup(fileIn)
			Self.addGroup(new_group)
		Wend
		
	End Method
	
	Method setValue(path:String, value:String)
		
		' First we try and get the variable
		Local parent:Object = Self.Query(path)
		If SodaGroup(parent) Then Throw "Cannot set value for entire group '" + path + "'"
		
		' Get the group and field name
		Local groupName:String 	= SodaFile._getGroupName(path)
		Local fieldName:String	= SodaFile._getFieldName(path)
		
		' Get the group
		Local group:SodaGroup	= Self.GetGroup(groupName)
		If group <> Null Then 
			group.AddField(fieldName, value)
		Else
			group = New SodaGroup
			group.SetIdentifier(groupName)
			group.AddField(fieldName, value)
			Self.addGroup(group)
		EndIf
			
	End Method
		
	' ------------------------------------------------------------
	' -- Internal methods
	' ------------------------------------------------------------
	
	Method addGroup(group:SodaGroup)
		If group Then Self._groups.addLast(group)
	End Method
	
	
	' ------------------------------------------------------------
	' -- Reading Elements
	' ------------------------------------------------------------
	
	''' <summary>Reads a group from a file stream.</summary>
	Method readGroup:SodaGroup(fileIn:TStream)
		
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
						currentValue:+ SodaFile.CHAR_LOOKUP[char]
					Else
						
						' Script source ([[ ]])
						If nextChar = ASC_SQUARE_OPEN Then 
							currentValue = Self.readScriptSource(fileIn)
						Else
							If group.Identifier = "" Then 
								Self.readGroupIdentifier(fileIn, group)
							Else
								fileIn.Seek(fileIn.Pos() - 1)
								group.addChild(Self.readGroup(fileIn))
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
						If Not( inField ) Then currentValue:+ SodaFile.CHAR_LOOKUP[char]
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
							shorthandGroup:SodaGroup = Self.GetGroup(groupName)
						EndIf
						
						If shorthandGroup = Null Then
							shorthandGroup = New SodaGroup
							shorthandGroup.SetIdentifier(groupName)
							
							If group <> Null Then
								group.AddChild(shorthandGroup)
							Else
								Self.addGroup(shorthandGroup)
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
							currentField:+ SodaFile.CHAR_LOOKUP[char]
						Else
							currentValue:+ SodaFile.CHAR_LOOKUP[char]
						EndIf
					EndIf
				
				' Start of a group (absorbed in GetGroupIdentifier)	
				Case ASC_CURLY_OPEN
					If inField = False Or inString Then currentValue:+ SodaFile.CHAR_LOOKUP[char]
					
				' Group terminator
				Case ASC_CURLY_CLOSE
				
					' [todo] - If the current line has not been terminated, should throw an error here!
				
					If inString Then 
						currentValue:+ SodaFile.CHAR_LOOKUP[char]
					Else 
						Return group
					EndIf
						
				' Any other char - add to fieldName or fieldValue
				Default;
					If char > 31 Then 
						If inField Then
							currentField:+ SodaFile.CHAR_LOOKUP[char]
						Else
							currentValue:+ SodaFile.CHAR_LOOKUP[char] 'token:+ char
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
				name:+ SodaFile.CHAR_LOOKUP[charIn]
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
				script:+ SodaFile.CHAR_LOOKUP[char]
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
				txt:+ SodaFile.CHAR_LOOKUP[char]
			End If
		Wend
		
		Return txt
		
	End Method
	
	''' <summary>Resets the internal cache.</summary>
	Method resetCache()
		Self._queryCache.Clear()
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

SodaFile.CHAR_LOOKUP = New String[256]

For Local i:Int = 0 To 255
	SodaFile.CHAR_LOOKUP[i] = Chr(i)
Next
