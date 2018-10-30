' ------------------------------------------------------------------------------
' -- src/expression_evaluate.bmx
' --
' -- Used to evaluate expressions within properties. Anthing inside a ${} block
' -- is parsed and the approprate code called.
' --
' -- This is a port of code used by the original BlitzBuild so it's rather
' -- unpleasant in places.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2018 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.map
Import brl.reflection

Import "expression_tokeniser.bmx"
Import "script_object.bmx"
Import "function_set.bmx"
Import "script_function.bmx"

Type ExpressionEvaluator

	Const MODE_EVALUATE:Byte   = 1
	Const MODE_PARSE_ONLY:Byte = 2

	' General use fields.
	Field _evalMode:Byte
	Field _tokeniser:ExpressionTokeniser
	Field _registeredFunctions:TMap

	' BlitzBuild specific fields.
	Field _properties:TMap


	' ------------------------------------------------------------
	' -- Public API
	' ------------------------------------------------------------

	''' <summary>
	''' Register a FunctionSet with the evaluator. Scans the set object for
	''' public methods (i.e. no `_` prefix) that have a name set in their meta
	''' data. These methods are then available for use in expressions.
	''' <summary>
	''' <param name="set">The FunctionSet object to add.</param>
	Method registerFunctionSet(set:FunctionSet)

		Local setType:TTypeId = TTypeId.ForObject(set)
		For Local fnc:TMethod = EachIn setType.Methods().Values()

			' Skip private methods and constructor.
			If fnc.Name().StartsWith("_") Or fnc.Name() = "New" Then Continue

			' Get function call name from meta.
			Local name:String = fnc.MetaData("name")

			' Register the function if it has a name.
			If name <> "" Then
				Self._registeredFunctions.Insert(name, ScriptFunction.Create(set, fnc))
			EndIf

		Next

	End Method

	''' <summary>Register a ScriptFunction object to use.</summary>
	Method registerFunction(func:ScriptFunction)
		Self._registeredFunctions.Insert(func.getFullName(), func)
	End Method

	Method registerStringProperty(name:String, value:String)
		Self._properties.Insert(name, ScriptObjectFactory.NewString(value))
	End Method

	Method registerFloatProperty(name:String, value:Float)
		Self._properties.Insert(name, ScriptObjectFactory.NewFloat(value))
	End Method

	Method registerIntProperty:Int(name:String, value:Int)
		Self._properties.Insert(name, ScriptObjectFactory.NewInt(value))
	End Method

	' Merge a list of properties
	Method addProperties(propertyList:Tmap)
		If propertyList = Null Then Return
		For Local keyName:String = EachIn propertyList.Keys()
			' TODO: Call `registerStringProperty` here instead.
			Self._properties.Insert(keyName, ScriptObjectFactory.NewString(String(propertyList.ValueForKey(keyName))))
		Next
	End Method


	' ------------------------------------------------------------
	' -- MAIN ENTRY
	' ------------------------------------------------------------

	Function quickEvaluate:ScriptObject(expression:String)

		If expression = Null Then Return Null

		Local eval:ExpressionEvaluator = ExpressionEvaluator.Create(expression)
		Local result:ScriptObject = eval.Evaluate()
		eval = Null
		Return result

	End Function

	Method evaluate:ScriptObject()

		Local result:ScriptObject = Self.parseExpression()

		' TODO: Wrap this in `tokeniser.isEof`
		If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_EOF Then
			Throw("Unexpected Char at end of expression: " + Self._tokeniser.CurrentToken)
		EndIf

		Return result

	End Method


	' ------------------------------------------------------------
	' -- Evaluation Methods
	' ------------------------------------------------------------

	Method parseExpression:ScriptObject()
		Return Self.parseBooleanOr()
	End Method

	' TODO: Should this be called `evaluateBooleanOr`?
	Method parseBooleanOr:ScriptObject()

		Local o1:ScriptObject		= Self.ParseBooleanAnd()

		While Self._tokeniser.isKeyword("or")

			' Get the left hand side.
			Local v1:ScriptObject = ScriptObjectFactory.NewBool(True)

			If Self._evalMode <> MODE_PARSE_ONLY Then

				' If true, we're done (because it's an or)
				v1 = o1
				If Int(v1.ToString()) Then
					Self._evalMode = MODE_PARSE_ONLY
				EndIf

			EndIf

			' Right hand side
			Self._tokeniser.getNextToken()
			Local o2:ScriptObject		= Self.ParseBooleanAnd()

			If Self._evalMode <> MODE_PARSE_ONLY Then
				Local v2:ScriptObject = o2
				' TODO: Wrap this in a helper called `compareValues`
				o1 = ScriptObjectFactory.NewBool(Int(v1.ToString()) Or Int(v2.ToString()))
			EndIf

		Wend

		Return o1

	End Method

	Method parseBooleanAnd:ScriptObject()

		Local p0:Int	= Self._tokeniser.CurrentPosition
		Local o:ScriptObject	= Self.ParseRelationalExpression()

		Local oldEvalMode:Int	= Self._evalMode

		While(Self._tokeniser.IsKeyword("and"))

			' Get the left hand side
			Local v1:ScriptObject	= ScriptObjectFactory.NewBool( True )

			If Self._evalMode <> MODE_PARSE_ONLY Then

				'  If false, we're done (because it's an and)
				v1 = o

				If Int(v1.ToString()) = False Then
					' We're done - result must be false now
					Self._evalMode = MODE_PARSE_ONLY
				EndIf

			EndIf

			' Right hand side
			Self._tokeniser.GetNextToken()

			Local p2:Int		= Self._tokeniser.CurrentPosition
			Local o2:ScriptObject	= Self.ParseRelationalExpression()
			Local p3:Int	= Self._tokeniser.CurrentPosition

			If Self._evalMode <> MODE_PARSE_ONLY Then
				Local v2:ScriptObject	= o2
				o				= ScriptObjectFactory.NewBool( v1 And v2 )
			EndIf

		Wend

		Return o

	End Method

	' TODO: Fix all of these :D
	Method parseRelationalExpression:ScriptObject()

		Local o:ScriptObject = Self.ParseAddSubtract()

		If Self._tokeniser.IsRelationalOperator() Then

			Local op:Int = Self._tokeniser.CurrentToken
			Self._tokeniser.GetNextToken()

			Local o2:ScriptObject = Self.ParseAddSubtract()

			If Self._evalMode = MODE_PARSE_ONLY Then Return Null

			Select op

				' Equals operator
				Case ExpressionTokeniser.TOKEN_EQUAL
					Return ScriptObjectFactory.NewBool(o = o2)

				Case ExpressionTokeniser.TOKEN_NOT_EQUAL
					Return ScriptObjectFactory.NewBool(o <> o2)

				Case ExpressionTokeniser.TOKEN_LT
					Return ScriptObjectFactory.NewBool(Int(o.ToString()) < Int(o2.ToString()))

				Case ExpressionTokeniser.TOKEN_GT
					Return ScriptObjectFactory.NewBool(Int(o.ToString()) > Int(o2.ToString()))

				Case ExpressionTokeniser.TOKEN_LE
					Return ScriptObjectFactory.NewBool(Int(o.ToString()) <= Int(o2.ToString()))

				Case ExpressionTokeniser.TOKEN_GE
					Return ScriptObjectFactory.NewBool(Int(o.ToString()) >= Int(o2.ToString()))

			End Select

		EndIf

		Return o

	End Method

	Method parseAddSubtract:ScriptObject()

		Local p0:Int	= Self._tokeniser.CurrentPosition
		Local o:ScriptObject	= Self.ParseMulDiv()
		Local o2:ScriptObject
		Local p3:Int

		While(True)

			If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_PLUS Then

				Self._tokeniser.GetNextToken()
				o2:ScriptObject		= Self.ParseMulDiv()
				p3		= Self._tokeniser.CurrentPosition

				If Self._evalMode <> MODE_PARSE_ONLY Then

					If ScriptObject.CanAdd(o, o2) Then
						o = ScriptObject.AddObjects(o, o2)
					Else
						RuntimeError("Can't ADD")
					EndIf

				EndIf

			ElseIf Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_MINUS Then

				Self._tokeniser.GetNextToken()
				o2:ScriptObject		= Self.ParseMulDiv()
				p3		= Self._tokeniser.CurrentPosition

				If Self._evalMode <> MODE_PARSE_ONLY Then
					If ScriptObject.CanAdd(o, o2) Then
						o = ScriptObject.SubtractObjects(o, o2)
					Else
						RuntimeError("Can't SUBTRACT")
					EndIf

				EndIf

			Else
				Exit
			EndIf

		Wend

		Return o

	End Method

	Method parseMulDiv:ScriptObject()

		Local p0:Int	= Self._tokeniser.CurrentPosition
		Local o:ScriptObject	= Self.ParseValue()
		Local o2:ScriptObject
		Local p3:Int

		Repeat

			If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_MUL Then

				Self._tokeniser.GetNextToken()
				o2	= Self.ParseValue()
				p3	= self._tokeniser.CurrentPosition

				If Self._evalMode <> MODE_PARSE_ONLY Then
					if ScriptObject.CanMultiply(o, o2) Then
						o = ScriptObject.MultiplyObjects(o, o2)
					Else
						RuntimeError("Can't MULTIPLY")
					End If

				EndIf

			ElseIf Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_DIV Then

				Self._tokeniser.GetNextToken()
				o2	= Self.ParseValue()
				p3	= Self._tokeniser.CurrentPosition

				If o2 = Null Then Self._throwSyntaxError()

				If self._evalMode <> MODE_PARSE_ONLY Then

					If ScriptObject.CanMultiply(o, o2) Then
						o = ScriptObject.DivideObjects(o, o2)
					Else
						RuntimeError("Can't DIVIDE")
					End If

				EndIf

			ElseIf  Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_MOD Then

				Self._tokeniser.GetNextToken()
				o2	= Self.ParseValue()
				p3	= self._tokeniser.CurrentPosition

				If self._evalMode <> MODE_PARSE_ONLY Then

					' Check for division by zero
				'	If (o2\m_Type = OBJ_INT And o2\m_ValueInt = 0) Or (o2\m_Type = OBJ_FLOAT And o2\m_ValueFloat = 0) Then
				'		RuntimeError("attempted mod by zero")
				'	EndIf

					If ScriptObject.CanMultiply(o, o2) Then
						o = ScriptObject.ModObjects(o, o2)
					Else
						RuntimeError("Can't MOD")
					End If

				EndIf

			Else

				Exit

			EndIf

		Forever

		Return o

	End Method

	Method parseConditional:ScriptObject()
		Throw "Not implemented :("
		Return Null
	End Method

	Method parseValue:ScriptObject()

		' -- Setup
		Local val:ScriptObject
		Local p0:Int
		Local p1:Int

		' -- Plain string values
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_STRING Then
			val = ScriptObjectFactory.NewString(Self._tokeniser.TokenText)
			Self._tokeniser.GetNextToken()
			Return val
		EndIf

		' -- Plain number values
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_NUMBER Then

			Local number:String = Self._tokeniser.TokenText

			p0	= self._tokeniser.CurrentPosition
			Self._tokeniser.GetNextToken()
			p1	= self._tokeniser.CurrentPosition - 1

			' Check for fractions
			If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_DOT Then
				number = number + "."
				Self._tokeniser.GetNextToken()

				' Check there's a number after the decimal point
				If Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_NUMBER Then
					Self._throwSyntaxError()
				EndIf

				number = number + Self._tokeniser.TokenText

				Self._tokeniser.GetNextToken()

				' Check for error
				p1 = self._tokeniser.CurrentPosition

				' Done
				Return ScriptObjectFactory.NewFloat(Float(number))

			' Integer
			Else
				Return ScriptObjectFactory.NewInt(Int(number))
			EndIf

		EndIf

		' -- Negative numbers
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_MINUS Then

			Self._tokeniser.GetNextToken()

			' Unary minus
			p0	= self._tokeniser.CurrentPosition
			val	= Self.ParseValue()
			p1	= self._tokeniser.CurrentPosition

			If self._evalMode <> MODE_PARSE_ONLY Then

				' Update object value
				'Select val\m_Type
			'		Case OBJ_INT	: val\m_ValueInt	= -val\m_ValueInt
			'		Case OBJ_FLOAT	: val\m_ValueFloat	= -val\m_ValueFloat
			'	End Select

				val = ScriptObject.SubtractObjects(ScriptObjectFactory.NewInt(0), val)

				Return val

			EndIf

			Return Null

		EndIf

		' Boolean "NOT"
		If Self._tokeniser.IsKeyword("not") Then

			Self._tokeniser.GetNextToken()

			p0	= self._tokeniser.CurrentPosition
			val	= Self.ParseValue()
			p1	= self._tokeniser.CurrentPosition

			If self._evalMode <> MODE_PARSE_ONLY Then

				' Update object value
				val = ScriptObjectFactory.NewInt(Not(val.valueInt()))
			'	val\m_ValueInt = Not(val\m_ValueInt)
				Return val

			EndIf

			Return Null

		EndIf

		' Brackets
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_LEFT_PAREN Then

			Self._tokeniser.GetNextToken()

			val	= Self.ParseExpression()

			If Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
				' Throw error
				RuntimeError("')' expected at " + self._tokeniser.CurrentPosition)
			EndIf

			Self._tokeniser.GetNextToken()
			Return val

		EndIf

		' Keywords (big chunk of code)
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_KEYWORD Then

			p0 = self._tokeniser.CurrentPosition

			Local functionOrPropertyName:String = Self._tokeniser.TokenText

			Select Lower(functionOrPropertyName)
				Case "if"		; Return Self.ParseConditional()
				Case "true"		; Self._tokeniser.GetNextToken() ; Return ScriptObjectFactory.NewBool(True)
				Case "false"	; Self._tokeniser.GetNextToken()  ; Return ScriptObjectFactory.NewBool(False)
			End Select

			' Switch off "ignore whitespace" as properties shouldn't contain spaces
			'this\_tokeniser\IgnoreWhitespace = False
			Self._tokeniser.GetNextToken()

			Local args:TList	= New TList
			Local isFunction:Int	= False

			' Get the current property or function name
			If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_DOUBLE_COLON Then

				' Function
				isFunction = True
				functionOrPropertyName = functionOrPropertyName + "::"
				Self._tokeniser.GetNextToken()

				' Check the :: is followed by a keyword
				If Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_KEYWORD Then
					RuntimeError("Function name expected")
				EndIf

				functionOrPropertyName = functionOrPropertyName + Self._tokeniser.TokenText
				Self._tokeniser.GetNextToken()

			Else

				' Property
				' TODO: This is so ugly it hurts. Fix it.
				While(Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_DOT Or Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_MINUS Or Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_KEYWORD Or Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_NUMBER)
					functionOrPropertyName = functionOrPropertyName + Self._tokeniser.TokenText
					Self._tokeniser.GetNextToken()
				Wend

			EndIf

			' Switch whitespace back on
			Self._tokeniser.IgnoreWhitespace = True

			' If we're at a space, get the next token
			If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_WHITESPACE Then
				Self._tokeniser.GetNextToken()
			EndIf

			' -- Execute the function

			' TODO: Split this into a new method
			If isFunction Then

				' Check for opening bracket (for params)
				If Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_LeFT_PAREN Then
					RuntimeError("'(' expected at " + self._tokeniser.CurrentPosition)
				EndIf

				Self._tokeniser.GetNextToken()

				' TODO: Fix function arguments
				Local currentArgument:Int			= 0
				Local parameterCount:Int		= Self._countFunctionParameters(functionOrPropertyName)

				' TODO: Replace with proper bug checking
'				If formalParameters = Null Then
'					RuntimeError("Function '" + functionOrPropertyName + "' not found")
'				EndIf

				While (Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN And Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_EOF)

					If currentArgument > parameterCount Then
						RuntimeError("Function ~q" + functionOrPropertyName + "~q -- Too many parameters")
					EndIf

					' Only parse if we have parameters
					If parameterCount > 0 Then

						Local beforeArg:Int		= Self._tokeniser.CurrentPosition
						Local e:ScriptObject	= Self.ParseExpression()
						Local afterArg:Int		= Self._tokeniser.CurrentPosition

						' Evaluate (will skip in parse only mode)
						If self._evalMode <> MODE_PARSE_ONLY Then

							' Convert to the required param & add to the list of params
							Local convertedValue:ScriptObject	= e

							args.AddLast(convertedValue.ToString())
							'args.AddLast(formalParameters.ValueAtIndex(currentArgument))

						EndIf

						currentArgument = currentArgument + 1

					EndIf

					' Check if we're at the end
					If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
						Exit
					EndIf

					' Check if there was no comma (syntax error)
					If Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_COMMA Then
						RuntimeError("',' expected at " + Self._tokeniser.CurrentPosition + " -- found " + Self._tokeniser.CurrentToken)
					EndIf

					Self._tokeniser.GetNextToken()

				Wend

				If currentArgument < parameterCount Then
					RuntimeError("Function ~q" + functionOrPropertyName + "~q -- Not enough parameters")
				EndIf

				If Self._tokeniser.CurrentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
					RuntimeError("')' expected at " + self._tokeniser.CurrentPosition)
				EndIf

				Self._tokeniser.GetNextToken()

			EndIf

			' Either run a function or get a property value
			If self._evalMode <> MODE_PARSE_ONLY Then
				If isFunction
					Return Self.EvaluateFunction(functionOrPropertyName, args)
				Else
					Return Self.EvaluateProperty(functionOrPropertyName)
				EndIf
			Else
				' Return nothing if we're just checking syntax
				Return Null
			EndIf

		EndIf

		Return Null

	End Method

	Method evaluateFunction:ScriptObject(functionName:String, argList:TList = Null)

		' Get the function object
		' TODO: Extract this to `getFunction`
		Local func:ScriptFunction = Scriptfunction(Self._registeredFunctions.ValueForKey(functionName))
		If func = Null Then Throw "No handler found for function '" + functionName + "'"

		' TODO: Don't need to call this __invoke
		Return func.__invoke(argList)

	End Method

	Method evaluateProperty:ScriptObject(propertyName:String)
		' TODO: Extract this to `getProperty`
		Return ScriptObject(Self._properties.ValueForKey(propertyName))
	End Method


	' ------------------------------------------------------------
	' -- Internal script stuff
	' ------------------------------------------------------------

	Method _countFunctionParameters:Int(functionName:String)
		Local func:ScriptFunction = scriptfunction(Self._registeredFunctions.ValueForKey(functionName))
		If func = Null Then Throw "No handler found for function '" + functionName + "'"

		Return func.countFunctionParameters()
	End Method


	' ------------------------------------------------------------
	' -- Auto setup support
	' ------------------------------------------------------------

	Method __autoload()

		' Auto add functionset objects
		Local base:TTypeId = TTypeId.ForName("FunctionSet")
		For Local setType:TTypeId = EachIn base.DerivedTypes()

			' Create a function set
			Local set:FunctionSet	= FunctionSet(setType.NewObject())

			' Setup args
			Self.RegisterFunctionSet(set)
		Next

	End Method


	' ------------------------------------------------------------
	' -- Error handling
	' ------------------------------------------------------------

	' TODO: Throw an actual type here
	Method _throwSyntaxError()
		Throw "Syntax error in expression: + ~q" + Self._tokeniser.getExpressionText() + "~q"
	End Method

	' debug
	Method __dumpProperties()
		For Local key:String = EachIn Self._properties.Keys()
			Print LSet(key, 20) + " => " + Self._properties.ValueForKey(key).ToString()
		Next
	End Method


	' ------------------------------------------------------------
	' -- Creation / Destruction
	' ------------------------------------------------------------

	Function Create:ExpressionEvaluator(expression:String)

		Local this:ExpressionEvaluator = New ExpressionEvaluator
		this._tokeniser = ExpressionTokeniser.Create(expression)
		Return this

	End Function

	Method New()
		Self._registeredFunctions	= New TMap
		Self._properties			= New TMap
		Self._evalMode				= MODE_EVALUATE
	End Method

End Type
