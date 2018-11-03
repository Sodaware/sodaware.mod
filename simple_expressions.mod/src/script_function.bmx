' ------------------------------------------------------------------------------
' -- src/expressions/script_function.bmx
' --
' -- Base type for functions that can be executed in an expression. Each script
' -- function must extend this type and set a name and handler.
' --
' -- The recommended method is to extend `FunctionSet` and use methods instead.
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

Type SimpleExpressions_Function

	Field _fullName:String
	Field _parentSet:SimpleExpressions_FunctionSet
	Field _method:TMethod
	Field _parameterCount:Int


	' ------------------------------------------------------------
	' -- Public API
	' ------------------------------------------------------------

	Method getFullName:String()
		Return Self._fullName
	End Method

	Method countFunctionParameters:Int()
		Return Self._parameterCount
	End Method


	' ------------------------------------------------------------
	' -- Exectution
	' ------------------------------------------------------------

	Method execute:ScriptObject(args:ScriptObject[])
		Local result:Object = Self._method.Invoke(Self._parentSet, args)
		Return ScriptObjectFactory.FromObject(result)
	End Method


	' ------------------------------------------------------------
	' -- Creation
	' ------------------------------------------------------------

	Function Create:SimpleExpressions_Function(set:SimpleExpressions_FunctionSet, handler:TMethod)
		Local this:SimpleExpressions_Function = New SimpleExpressions_Function

		this._parentSet      = set
		this._method         = handler
		this._parameterCount = handler.argTypes().Length

		Return this
	End Function

End Type
