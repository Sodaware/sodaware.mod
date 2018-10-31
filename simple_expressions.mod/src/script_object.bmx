' ------------------------------------------------------------------------------
' -- src/script_object.bmx
' --
' -- Generic object used to represent values within scripts. Originally used
' -- because BlitzPlus lacked reflection and various OO features.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2018 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.reflection

Include "script_object_factory.bmx"

Type ScriptObject

	' Object Types
	Const OBJECT_INT:Byte    = 1
	Const OBJECT_FLOAT:Byte  = 2
	Const OBJECT_STRING:Byte = 4
	Const OBJECT_BOOL:Byte   = 8


	Field _type:Byte
	Field _value:Object


	' ------------------------------------------------------------
	' -- Fetcing Values
	' ------------------------------------------------------------

	Method valueBool:Byte()
		Local val:String = Self._value.ToString().toLower()
		If val = 0 Then Return False
		If val = "false" Then Return False

		Return True
	End Method

	Method valueInt:Int()
		Return Int(Self._value.ToString())
	End Method

	Method valueFloat:Float()
		Return Float(Self._value.ToString())
	End Method

	Method valueString:String()
		Return Self._value.ToString()
	End Method

	Method toString:String()
		Return Self.valueString()
	End Method

	' Debug only!
	Method dump:String()
		Return "<" + Self.objectTypeToString() + "> " + Self.valueString()
	End Method

	Method objectTypeToString:String()
		Select Self._Type
			Case OBJECT_INT
				Return "Int"

			Case OBJECT_FLOAT
				Return "Float"

			Case OBJECT_STRING
				Return "String"

			Case OBJECT_BOOL
				Return "Bool"

			Default
				Return "UNKNOWN"

		End Select
	End Method

	Function AddObjects:ScriptObject(o1:ScriptObject, o2:ScriptObject)

		' Can always add strings.
		If o1._type = OBJECT_STRING Or o2._type = OBJECT_STRING Then
			Return ScriptObjectFactory.NewString(o1.valueString() + o2.valueString())
		EndIf

		' Adding ints
		If o1._type = OBJECT_INT And o1._type = OBJECT_INT Then
			Return ScriptObjectFactory.NewInt(o1.valueInt() + o2.valueInt())
		End If

		' Adding floats
		If o1._type = OBJECT_FLOAT And o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) + Float(o2._value.ToString()))
		End If

		' Adding mixed floats.
		If o1._type = OBJECT_FLOAT Or o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) + Float(o2._value.ToString()))
		End If

		Return Null

	End Function

	Function SubtractObjects:ScriptObject(o1:ScriptObject, o2:ScriptObject)

		' Can always dubtract strings
		If o1._type = OBJECT_STRING Or o2._type = OBJECT_STRING Then
			Return ScriptObjectFactory.NewString(String(o1._value).Replace(String(o2._value), ""))
		EndIf

		' Subtracting ints
		If o1._type = OBJECT_INT And o1._type = OBJECT_INT Then
			Return ScriptObjectFactory.newint(Int(o1._value.ToString()) - Int(o2._value.ToString()))
		End If

		' Subtracting floats
		If o1._type = OBJECT_FLOAT And o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) - Float(o2._value.ToString()))
		End If

		' Subtracting mixed
		If o1._type = OBJECT_FLOAT Or o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) - Float(o2._value.ToString()))
		End If

		Return Null

	End Function

	Function MultiplyObjects:ScriptObject(o1:ScriptObject, o2:ScriptObject)

		If o1._type = OBJECT_INT And o1._type = OBJECT_INT Then
			Return ScriptObjectFactory.newint(Int(o1._value.ToString()) * Int(o2._value.ToString()))
		End If

		' Subtracting floats
		If o1._type = OBJECT_FLOAT And o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) * Float(o2._value.ToString()))
		End If

		' Subtracting mixed
		If o1._type = OBJECT_FLOAT Or o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) * Float(o2._value.ToString()))
		End If

		Return Null

	End Function

	Function DivideObjects:ScriptObject(o1:ScriptObject, o2:ScriptObject)

		If o1._type = OBJECT_INT And o1._type = OBJECT_INT Then
			Return ScriptObjectFactory.newint(Int(o1._value.ToString()) / Int(o2._value.ToString()))
		End If

		' Subtracting floats
		If o1._type = OBJECT_FLOAT And o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) / Float(o2._value.ToString()))
		End If

		' Subtracting mixed
		If o1._type = OBJECT_FLOAT Or o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) / Float(o2._value.ToString()))
		End If

		Return Null

	End Function

	Function ModObjects:ScriptObject(o1:ScriptObject, o2:ScriptObject)

		If o1._type = OBJECT_INT And o1._type = OBJECT_INT Then
			Return ScriptObjectFactory.newint(Int(o1._value.ToString()) Mod Int(o2._value.ToString()))
		End If

		' Subtracting floats
		If o1._type = OBJECT_FLOAT And o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) Mod Float(o2._value.ToString()))
		End If

		' Subtracting mixed
		If o1._type = OBJECT_FLOAT Or o1._type = OBJECT_FLOAT Then
			Return ScriptObjectFactory.NewFloat(Float(o1._value.ToString()) Mod Float(o2._value.ToString()))
		End If

		Return Null

	End Function

	' Can add:
	' Same types
	' float to int/vice versa
	' String to anything
	Function CanAdd:Int(o1:ScriptObject, o2:ScriptObject)

		If o1._type = o2._type Then Return True
		If o1._type + o2._type = 3 Then Return True
		If o1._type = Object_String Or o2._type = OBJECT_STRING Then Return True

		' Can't add
		Return False

	End Function

	Function CanMultiply:Int(o1:ScriptObject, o2:ScriptObject)

		If (o1._type = o2._type) And (o1._type = OBJECT_INT Or o1._type = OBJECT_FLOAT) Then Return True
		Return False

	End Function

End Type
