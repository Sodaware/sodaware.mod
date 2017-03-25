' ------------------------------------------------------------
' -- src/soda_field.bmx
' --
' -- A single field within a soda document
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.linkedlist

Type SodaField
	
	Field Name:String
	Field Value:Object
	
	Field m_ArrayValues:TList
	Field isArray:Int	= False
	
	Function Create:SodaField(name:String, value:Object, isArray:Int = False)
		Local this:SodaField = New SodaField
		this.name = name
		
		If isArray Then this.addToArray(value) Else this.value = value
		
		Return this
		
		
	End Function
	
	Method addToArray(val:Object)
		If Self.m_ArrayValues = Null Then Self.m_ArrayValues = New TList ; Self.isArray = True
		Self.m_ArrayValues.AddLast(val)
	End Method
	
	''' <summary>Gets the value of a field, with optional array offset.</summary>
	''' <param name="offset">Optional array offset. If not included and field is array, whole array will be returned.</param>
	Method getValue:Object(offset:Int = -1)
		
		' If field is array, check if we want an offset or the whole thing, ensuring a valid
		' offset was used.
		If Self.isArray Then
			
			If offset > -1 Then
				If offset >= Self.m_ArrayValues.Count() Then Return Null
				Return Self.m_ArrayValues.ValueAtIndex(offset)
			Else
				Return Self.m_ArrayValues		
			End If
			
		End If
		
		' Not array, so just return the value
		Return Self.Value
		
	End Method
	
	
End Type
