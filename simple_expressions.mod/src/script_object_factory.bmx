' ------------------------------------------------------------------------------
' -- src/expressions/script_object_factory.bmx
' --
' -- Creates `ScriptObject` instances.
' --
' -- This file is part of "blam" (https://www.sodaware.net/blam/)
' -- Copyright (c) 2007-2017 Phil Newton
' --
' -- See COPYING for full license information.
' ------------------------------------------------------------------------------


Type ScriptObjectFactory

	Function FromObject:ScriptObject(val:Object)
		Local objectType:TTypeId = TTypeId.ForObject(val)
		Select objectType.Name().ToLower()

			Case "string"
				Return ScriptObjectFactory.NewString(String(val))

			Case "int"
				Return ScriptObjectFactory.NewInt(Int(val.ToString()))

			Case "float"
				Return ScriptObjectFactory.NewFloat(Float(val.ToString()))

			Case "scriptobject"
				Return ScriptObject(val)

		End Select

		Throw "Unknown type: " + objectType.Name()
	End Function

	Function NewBool:ScriptObject(val:Int)
		Local this:ScriptObject = New ScriptObject

		this._type = ScriptObject.OBJECT_BOOL
		this._value = String(val)

		Return this
	End Function

	Function NewInt:ScriptObject(val:Int)
		Local this:ScriptObject = New ScriptObject

		this._type = ScriptObject.OBJECT_INT
		this._valueInt = val

		Return this
	End Function

	Function NewFloat:ScriptObject(val:Float)
		Local this:ScriptObject = New ScriptObject

		this._type = ScriptObject.OBJECT_FLOAT
		this._value = String(val)

		Return this
	End Function

	Function NewString:ScriptObject(val:String)
		Local this:ScriptObject = New ScriptObject

		this._type = ScriptObject.OBJECT_STRING
		this._value = String(val)

		Return this
	End Function

End Type
