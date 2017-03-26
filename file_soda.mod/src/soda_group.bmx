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
Import sodaware.blitzmax_ascii

Import "soda_field.bmx"
Import "soda_file_util.bmx"


Type SodaGroup

	Const INVALID_OFFSET:Int    = -2
	
	Field Identifier:String     = ""
	
	Field _isArray:Int          = False

	Field _meta:TMap            = New TMap
	Field _fields:TMap          = New TMap
	Field _numberOfFields:Int   = 0
	
	Field _childLookup:TMap     = New TMap
	Field _children:TList       = New TList
	Field _childrenCount:Int    = 0
	
	
	' ------------------------------------------------------------
	' -- Public API
	' ------------------------------------------------------------
	
	Method countFields:Int()
		Return Self._numberOfFields
	End Method
	
	Method countChildren:Int()
		Return Self._childrenCount
	End Method
	
	' TODO: SLOW
	Method getFieldNames:TList()
		Local fieldNames:TList = New TList
		For Local keyName:String = EachIn Self._fields.Keys()
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
	Method query:Object(qry:String)
	
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
	
	Method getChild:SodaGroup(ident:String, offset:Int = -1)
		
		If Self._childLookup = Null Then Return Null
		
		' TODO: Fix this for idents with offsets
		Local grp:SodaGroup = SodaGroup(Self._childLookup.ValueForKey(ident))
		
		If grp = Null Then Return Null
	
		If grp._isArray Then
			
			If offset = -1 Then Return grp
			
			Local currentOffset:Int = -1
			For Local g:SodaGroup = EachIn Self._children
				
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
		If Self._fields = Null Then Return defaultValue
		
		Local val:SodaField = Sodafield(Self._fields.ValueForKey(fieldName))
		
		If val = Null Then Return defaultValue		
		
		Return val.getValue(offset)
	End Method
	
	Method getFieldString:String(fieldName:String, offset:Int = -1, defaultValue:String = "")
		Return String(Self.getField(fieldName, offset, defaultValue))
	End Method
	
	Method getChildren:TList(name:String = "")
		If name = "" Then Return Self._children
		Local children:TList = New TList
		For Local child:SodaGroup = EachIn Self._children
			If child.GetIdentifier() = name Then children.AddLast(child)
		Next
		Return children
	End Method
	
	Method getMeta:String(name:String)
		Return String( Self._meta.ValueForKey(name.ToLower()) )
	End Method

	Method setMeta(name:String, value:String)
		Self._meta.Insert(name, value)
	End Method

	
	' ------------------------------------------------------------
	' -- Adding children and fields
	' ------------------------------------------------------------
	
	Method addChild(child:SodaGroup)
		If child = Null Then Return
		
		' Add to list of children and to the lookup
		Self._children.AddLast(child)
		Self._childLookup.Insert(child.Identifier, child)
		Self._childrenCount :+ 1		
	End Method
	
	Method addField(fieldName:String, fieldValue:String, isArray:Byte = False)
	
		If fieldName[fieldName.Length - 1] = ASC_ASTERISK Then isArray = True
		
		If isArray Then
			Local val:SodaField = Sodafield(Self._fields.ValueForKey(fieldName))
			If val = Null Then
				val:SodaField = SodaField.Create(fieldName, fieldValue, isArray)
				Self._fields.Insert(fieldName, val)
				Self._numberOfFields:+ 1
			Else
				val.addToArray(fieldValue)
			End If
			
		Else
			Self._fields.Insert(fieldName, SodaField.Create(fieldName, fieldValue, isArray))
			Self._numberOfFields:+ 1
		EndIf
		
	End Method
	
	Method fieldIsArray:Byte(fieldName:String)
		Local val:SodaField = Sodafield(Self._fields.ValueForKey(fieldName))
		If val = Null Then Return False
		Return val.isArray()
	End Method
	
	
	' ------------------------------------------------------------
	' -- Internal methods
	' ------------------------------------------------------------
	
	Method setIdentifier(identifierText:String)
		
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
			Self._meta.Insert(pairs[0].ToLower(), pairs[1])
		Next
		
		If Self._meta.IsEmpty() Then 
			Self.Identifier = identifierText 
		else
			Self.Identifier = String(Self._meta.ValueForKey("n"))
		EndIf
		
	End Method
	
End Type
