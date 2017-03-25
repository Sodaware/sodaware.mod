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
Import "soda_file_exceptions.bmx"

Include "soda_file_loader.bmx"


Type SodaFile
	
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
		Return SodaFile_Loader.load(url)
	End Function
	
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
	
	''' <summary>Resets the internal cache.</summary>
	Method resetCache()
		Self._queryCache.Clear()
	End Method
	
End Type
