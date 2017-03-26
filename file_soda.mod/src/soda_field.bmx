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
	
	Field _name:String
	Field _value:Object
	Field _arrayValues:TList
	Field _isArray:Byte
	
	
	' ------------------------------------------------------------
	' -- Getting info
	' ------------------------------------------------------------
	
	''' <summary>Get the name of the field.</summary>
	Method getName:String()
		Return Self._name
	End Method
	
	''' <summary>Gets the value of a field, with optional array offset.</summary>
	''' <param name="offset">Optional array offset. If not included and field is array, whole array will be returned.</param>
	Method getValue:Object(offset:Int = -1)
		
		' If field is array, check if we want an offset or the whole thing, ensuring a valid
		' offset was used.
		If Self._isArray Then
			
			If offset > -1 Then
				If offset >= Self._arrayValues.Count() Then Return Null
				Return Self._arrayValues.ValueAtIndex(offset)
			Else
				Return Self._arrayValues		
			End If
			
		End If
		
		' Not array, so just return the value
		Return Self._value
		
	End Method
	
	Method isArray:Byte()
		Return Self._isArray
	End Method
	
	Method addToArray(val:Object)
		If Self._arrayValues = Null Then
			Self._arrayValues = New TList
			Self._isArray = True
		EndIf
		Self._arrayValues.AddLast(val)
	End Method
	
	
	' ------------------------------------------------------------
	' -- Creation and Destruction
	' ------------------------------------------------------------
	
	''' <summary>Create a new SodaField with a name and value.</summary>
	''' <param name="name">The name of the field to create.</param>
	''' <param name="value">The value of the field.</param>
	''' <param name="isArray">Optional flag. If true, the field is an array.</param>
	''' <returns>The newly-created field.</returns>
	Function Create:SodaField(name:String, value:Object, isArray:Byte = False)
		
		Local this:SodaField = New SodaField
		
		this._name = name
		
		If isArray Then
			this.addToArray(value)
		Else 
			this._value = value
		EndIf
		
		Return this
		
	End Function
	
End Type
