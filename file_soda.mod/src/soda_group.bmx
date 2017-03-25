' ------------------------------------------------------------------------------
' -- src/soda_group.bmx
' -- 
' -- A group is a collection of fields within a SodaFile document.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.linkedlist
Import brl.map
Import brl.retro

Import brl.reflection

Import "soda_field.bmx"
Import "soda_file_util.bmx"

' ------------------------------------------------------------
' -- Soda file elements
' ------------------------------------------------------------

Type SodaGroup

	Const INVALID_OFFSET:Int	= -2
	
	Field m_IsArray:Int			= False

	Field Identifier:String	 	= ""
	Field m_Meta:TMap			= New TMap
	Field m_Fields:TMap			= New TMap
	Field m_NumberOfFields:Int	= 0
	
	Field m_ChildLookup:TMap	= New TMap
	Field m_Children:TList		= New TList
	
	
	' ------------------------------------------------------------
	' -- Public API
	' ------------------------------------------------------------
	
	Method getFieldNames:TList()
		Local fieldNames:TList = New TList
		For Local keyName:String = EachIn Self.m_Fields.Keys()
			fieldNames.AddLast(keyName)
		Next
		Return fieldNames
	End Method
	
	Method _getFieldOrChild:Object(name:String, offset:Int)
		
		Local result:Object = Self.GetField(name, offset)
		If result <> Null Then Return result
			
		' No field found, try a child
		Local child:SodaGroup = Self.GetChild(name, offset)
		If child <> Null Then Return child
			
		Return Null
		
	End Method
	
	''' <summary>Get a field or child via a simple query.</summary>
	Method Query:Object(qry:String)
	
		' Check inputs
		If qry = "" Then Return Null
	
		' -- Return value if at end of query
		If qry.Contains(".") = False Then 
			Return Self._getFieldOrChild(SodaFile_Util.GetName(qry), SodaFile_Util.GetOffset(qry))
		EndIf
		
		' Split into chunks
		Local identifiers:String[]	= qry.Split(".")
		Local rootGroup:SodaGroup	= Self.GetChild(SodaFile_Util.GetName(identifiers[0]), SodaFile_Util.GetOffset(identifiers[0]))
		
		' Check a valid base group was found
		If rootGroup = Null Then Return Null
		
		' Find the child - either a field or a child group
		For Local i:Int = 1 To identifiers.Length - 1
			
			Local name:String = SodaFile_Util.GetName(identifiers[i])
			Local offset:Int  = SodaFile_Util.GetOffset(identifiers[i])
			
			If name = "*" Then offset = -1
			
			' If we're at the last object, check
			If i = identifiers.Length - 1 Then
				Return rootGroup._getFieldOrChild(name, offset)
			Else
				Return rootGroup.Query(SodaFile_Util.AssembleQuery(identifiers))
			EndIf
			
		Next
		
		Return Null
	End Method
	
	Method queryString:String(query:String)
		Return String(Self.Query(query))
	End Method
	
	Method getIdentifier:String()
		Return Self.Identifier
	End Method
	
	Method GetMeta:String(name:String)
		Return String( Self.m_Meta.ValueForKey(name.ToLower()) )
	End Method

	Method SetMeta(name:String, value:String)
		Self.m_Meta.Insert(name, value)
	End Method

	Method AddChild(child:SodaGroup)
		Self.m_Children.AddLast(child)
		Self.m_ChildLookup.Insert(child.Identifier, child)
	End Method
	
	Method CountFields:Int()
		Return Self.m_NumberOfFields
	End Method
	
	Method AddField(fieldName:String, fieldValue:String, isArray:Int = False)
	
	'	Print "adding field: " + fieldName
		If Right(fieldName, 1) = "*" Then isArray = True
		
		If isArray Then
			Local val:SodaField = Sodafield(Self.m_Fields.ValueForKey(fieldName))
			If val = Null Then
				val:SodaField = SodaField.Create(fieldName, fieldValue, isArray)
				Self.m_Fields.Insert(fieldName, val)
				Self.m_NumberOfFields:+ 1
			Else
				val.addToArray(fieldValue)
			End If
			
		Else
			Self.m_Fields.Insert(fieldName, SodaField.Create(fieldName, fieldValue, isArray))
			Self.m_NumberOfFields:+ 1
		EndIf

	'	Self.m_Fields.Insert(fieldName, fieldValue)
		
'		Self.m_Fields.Insert(fieldName, fieldObject)
	End Method

	Method GetChild:SodaGroup(ident:String, offset:Int = -1)
		
		If Self.m_ChildLookup = Null Then Return Null
		
		' TODO: Fix this for idents with offsets
		Local grp:SodaGroup = SodaGroup(Self.m_ChildLookup.ValueForKey(ident))
		
		If grp = Null Then Return Null
	
		If grp.m_IsArray Then
			
			If offset = -1 Then Return grp
			
			Local currentOffset:Int = -1
			For Local g:SodaGroup = EachIn Self.m_Children
				
				If g.Identifier = grp.Identifier
					currentOffset:+1
				End If
				
				If currentOffset = offset Then Return g
			Next
			
			Return Null
		Else
			Return grp
		End If
		

	End Method
	
	Method getField:Object(fieldName:String, offset:Int = -1, defaultValue:Object = Null)
		If Self.m_Fields = Null Then Return defaultValue
		
		Local val:SodaField = Sodafield(Self.m_Fields.ValueForKey(fieldName))
		
		If val = Null Then Return defaultValue		
		
		Return val.getValue(offset)
	End Method
	
	Method getFieldString:String(fieldName:String, offset:Int = -1, defaultValue:String = "")
		Return String(Self.getField(fieldName, offset, defaultValue))
	End Method
	
	' TODO: Should be fast enough unless called lots of times.
	Method CountChildren:Int()
		Return Self.m_Children.Count()
	End Method
	
	Method GetChildren:TList(name:String = "")
		If name = "" Then Return Self.m_Children
		Local children:TList = New TList
		For Local child:SodaGroup = EachIn Self.m_Children
			If child.GetIdentifier() = name Then children.AddLast(child)
		Next
		Return children
	End Method
	
	Method FieldIsArray:Int(fieldName:String)
		Local val:SodaField = Sodafield(Self.m_Fields.ValueForKey(fieldName))
		If val = Null Then Return False
		Return val.isArray
	End Method
	
	' ------------------------------------------------------------
	' -- Internal methods
	' ------------------------------------------------------------
	
	Method SetIdentifier(identifierText:String)
		
		If identifierText = "" Then identifierText = "*"
	
		' If no special cases, return as is
		If identifierText.Contains(":") = False And identifierText.Contains(",") = False And identifierText.Contains(";") = False Then
			Self.Identifier = identifierText
			Return
		End If
		
		' Convert spaces / semi-colons
		Local cleanedIdentifier:String = identifierText.Replace(" ", "")
		cleanedIdentifier = cleanedIdentifier.Replace(";", ",")
		
		' Field name contains meta data
		Local fields:String[] = cleanedIdentifier.Split(",")
	
		' Go through fields, splitting into names / meta
		For Local fieldPair:String = EachIn fields
			Local pairs:String[] = fieldPair.Split(":")
			Self.m_Meta.Insert(pairs[0].ToLower(), pairs[1])
		Next

		
		If Self.m_Meta.IsEmpty() Then 
			Self.Identifier = identifierText 
		else
			Self.Identifier = String(self.m_Meta.ValueForKey("n"))
		EndIf

	
	End Method
	
End Type

