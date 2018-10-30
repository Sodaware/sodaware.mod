' ------------------------------------------------------------------------------
' -- src/expressions/script_function.bmx
' --
' -- Base type for functions that can be executed in an expression. Each script
' -- function must extend this type and set a name and handler.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2018 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.reflection

Import "script_object.bmx"
Import "function_set.bmx"


Type ScriptFunction

	Field _fullName:String
	Field _parentSet:FunctionSet
	Field _method:TMethod


	' ------------------------------------------------------------
	' -- Public API
	' ------------------------------------------------------------

	Method getFullName:String()
		Return Self._fullName
	End Method

	Method getArgList:TList()
		Return New TList
	End Method

	Method _getParam:Object(offset:Int)

	End Method

	Method countFunctionParameters:Int()
		Return Self._method.ArgTypes().Length
	End Method


	' ------------------------------------------------------------
	' -- Exectution
	' ------------------------------------------------------------

	Method execute:ScriptObject()
		Return ScriptObjectFactory.NewInt(20)
	End Method

	Method __invoke:ScriptObject(argList:TList)
		Local result:Object = Self._method.Invoke(Self._parentSet, argList.ToArray())
		Return ScriptObjectFactory.FromObject(result)
	End Method


	' ------------------------------------------------------------
	' -- Creation
	' ------------------------------------------------------------

	Function Create:ScriptFunction(set:FunctionSet, handler:TMethod)
		Local this:ScriptFunction = New ScriptFunction

		this._parentSet = set
		this._method    = handler

		Return this
	End Function

End Type
