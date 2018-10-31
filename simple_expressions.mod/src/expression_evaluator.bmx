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
	''' Register a FunctionSet with the evaluator.
	'''
	''' Scans the set object for public methods (i.e. no `_` prefix) that
	''' have a name set in their meta data. These methods are then available
	''' for use in expressions.
	''' <summary>
	''' <param name="set">The FunctionSet object to add.</param>
	Method registerFunctionSet(set:FunctionSet)

		Local setType:TTypeId = TTypeId.ForObject(set)
		For Local fnc:TMethod = EachIn setType.EnumMethods()

			' Skip private methods and constructor.
			If fnc.Name().StartsWith("_") Or fnc.Name() = "New" Then Continue

			' Get function call name from meta.
			Local name:String = fnc.MetaData("name")
			' Register the function if it has a name.
			If name <> "" Then
				Self._registeredFunctions.Insert(name, SimpleExpressions_Function.Create(set, fnc))
			EndIf

		Next

	End Method

	''' <summary>Register a SimpleExpressions_Function object to use.</summary>
	Method registerFunction(func:SimpleExpressions_Function)
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
			Self.registerStringProperty(keyName, String(propertyList.valueForKey(keyName)))
		Next
	End Method

	Method setExpression(expression:String)
		Self._tokeniser.setExpression(expression)
		Self._tokeniser.reset()
	End Method


	' ------------------------------------------------------------
	' -- MAIN ENTRY
	' ------------------------------------------------------------

	' Run an expression on a New expression evaluator instance.
	' Probably don't want to do this as it doesn't have functions and watnot setup.
	Function quickEvaluate:ScriptObject(expression:String)
		If expression = Null Then Return Null

		' Create a new evaluator.
		Local eval:ExpressionEvaluator = New ExpressionEvaluator

		' Evaluate the expression and return the result.
		Local result:ScriptObject = eval.evaluate(expression)
		eval = Null
		Return result

	End Function

	Method evaluate:ScriptObject(expression:String = "")

		' Set the expression.
		Self.setExpression(expression)

		' Run the expression.
		Local result:ScriptObject = Self.parseExpression()

		' TODO: Wrap this in `tokeniser.isEof`
		If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_EOF Then
			Throw("Unexpected Char at end of expression: " + Self._tokeniser.CurrentToken)
		EndIf

		Return result

	End Method


	''' <summary>
	''' Parse a string property and return its value. Will evaluate any
	''' expressions and functions within the property.
	''' </summary>
	''' <param name="value">The value to parse</param>
	''' <return>The parsed value.</return>
	Method interpolate:String(value:String)

		Local propertyValue:String = value
		While Instr(propertyValue, "${") > 0

			Local myExp:String = Mid(propertyValue, Instr(propertyValue, "${") + 2, Instr(propertyValue, "}") - Instr(propertyValue, "${") - 2)

			If Instr(propertyValue, "}") < 1 Then
				Throw "Missing closing brace in expression ~q" + propertyValue + "~q"
			EndIf

			' If expression has contents, work it !
			If myExp <> "" Then

				' -- Execute
				Local res:ScriptObject = Self.evaluate(myExp)
				If res = Null Then
					Print "Expression '" + myExp + "' returned a null result"
				End If

				' -- Replace expression with value
				propertyValue = propertyValue.Replace("${" + myExp + "}", res.ToString())
			Else
				propertyValue = propertyValue.Replace("${" + myExp + "}", "")
			EndIf

		Wend

		Return propertyValue

	End Method


	' ------------------------------------------------------------
	' -- Evaluation Methods
	' ------------------------------------------------------------

	' TODO: shouldn't this be evaluate
	Method parseExpression:ScriptObject()
		Return Self.parseBooleanOr()
	End Method

	' TODO: Should this be called `evaluateBooleanOr`?
	Method parseBooleanOr:ScriptObject()
		Local o1:ScriptObject = Self.parseBooleanAnd()

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

		Local leftSide:ScriptObject = Self.parseRelationalExpression()

		While Self._tokeniser.IsKeyword("and")

			If Self._evalMode <> MODE_PARSE_ONLY Then
				'  If false, we're done (because it's an and)
				If leftSide.valueBool() = False Then
					Self._evalMode = MODE_PARSE_ONLY
				EndIf
			EndIf

			' Right hand side
			Self._tokeniser.getNextToken()
			Local rightSide:ScriptObject = Self.parseRelationalExpression()

			If Self._evalMode <> MODE_PARSE_ONLY Then
				leftSide = ScriptObjectFactory.NewBool(leftSide.valueBool() And rightSide.valueBool())
			EndIf
		Wend

		Return leftSide

	End Method

	Method parseRelationalExpression:ScriptObject()

		Local o:ScriptObject = Self.parseAddSubtract()

		If Self._tokeniser.isRelationalOperator() Then

			Local op:Byte = Self._tokeniser.currentToken
			Self._tokeniser.getNextToken()

			Local o2:ScriptObject = Self.parseAddSubtract()

			If Self._evalMode = MODE_PARSE_ONLY Then Return Null

			' TODO: Replace int casting with value numeric?
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

		Local leftSide:ScriptObject  = Self.parseMulDiv()
		Local rightSide:ScriptObject = Null

		While True
			Select Self._tokeniser.currentToken

				Case ExpressionTokeniser.TOKEN_PLUS

					' Get the next item to add.
					Self._tokeniser.getNextToken()
					rightSide = Self.parseMulDiv()

					If Self._evalMode <> MODE_PARSE_ONLY Then
						If ScriptObject.canAdd(leftSide, rightSide) Then
							leftSide = ScriptObject.AddObjects(leftSide, rightSide)
						Else
							RuntimeError("Can't ADD")
						EndIf

					EndIf

				Case ExpressionTokeniser.TOKEN_MINUS

					Self._tokeniser.GetNextToken()
					rightSide = self.parseMulDiv()

					If Self._evalMode <> MODE_PARSE_ONLY Then
						If ScriptObject.canAdd(leftSide, rightSide) Then
							leftSide = ScriptObject.SubtractObjects(leftSide, rightSide)
						Else
							RuntimeError("Can't SUBTRACT")
						EndIf

					EndIf

				Default
					Exit

			End select

		Wend

		Return leftSide

	End Method

	Method parseMulDiv:ScriptObject()

		Local leftSide:ScriptObject  = Self.parseValue()
		Local rightSide:ScriptObject = Null

		Repeat

			Select Self._tokeniser.currentToken

				Case ExpressionTokeniser.TOKEN_MUL
					Self._tokeniser.GetNextToken()
					rightSide = Self.parseValue()

					If Self._evalMode <> MODE_PARSE_ONLY Then
						If ScriptObject.CanMultiply(leftSide, rightSide) Then
							leftSide = ScriptObject.MultiplyObjects(leftSide, rightSide)
						Else
							RuntimeError("Can't MULTIPLY")
						End If
					EndIf

				Case ExpressionTokeniser.TOKEN_DIV
					Self._tokeniser.getNextToken()
					rightSide = Self.parseValue()

					If rightSide = Null Then Self._throwSyntaxError()

					If self._evalMode <> MODE_PARSE_ONLY Then
						If ScriptObject.CanMultiply(leftSide, rightSide) Then
							leftSide = ScriptObject.DivideObjects(leftSide, rightSide)
						Else
							RuntimeError("Can't DIVIDE")
						End If
					EndIf

				Case ExpressionTokeniser.TOKEN_MOD
					Self._tokeniser.getNextToken()
					rightSide = Self.parseValue()

					If self._evalMode <> MODE_PARSE_ONLY Then
						' TODO: Check for division by zero
						If ScriptObject.CanMultiply(leftSide, rightSide) Then
							leftSide = ScriptObject.ModObjects(leftSide, rightSide)
						Else
							RuntimeError("Can't MOD")
						End If
					EndIf

				Default
					Exit

			End Select

		Forever

		Return leftSide

	End Method

	Method parseConditional:ScriptObject()
		Throw "Not implemented :("
		Return Null
	End Method

	' TODO: This is ugly'
	Method parseValue:ScriptObject()

		' -- Setup
		Local val:ScriptObject

		' -- In a string.
		If Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_STRING Then
			val = ScriptObjectFactory.NewString(Self._tokeniser.tokenText)
			Self._tokeniser.getNextToken()
			Return val
		EndIf

		' -- Plain number values
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_NUMBER Then

			Local number:String = Self._tokeniser.TokenText

			Self._tokeniser.GetNextToken()

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
			val	= Self.parseValue()

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

			Self._tokeniser.getNextToken()

			val	= Self.parseValue()

			If self._evalMode <> MODE_PARSE_ONLY Then
				Return ScriptObjectFactory.NewInt(Not(val.valueInt()))
			EndIf

			Return Null

		EndIf

		' Brackets.
		If Self._tokeniser.CurrentToken = ExpressionTokeniser.TOKEN_LEFT_PAREN Then

			Self._tokeniser.getNextToken()

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

			Local functionOrPropertyName:String = Self._tokeniser.tokenText

			' Built-in keywords.
			Select Lower(functionOrPropertyName)

				' TODO: Remvoe this!
				Case "if"
					Return Self.parseConditional()

				Case "true"
					Self._tokeniser.getNextToken()
					Return ScriptObjectFactory.NewBool(True)

				Case "false"
					Self._tokeniser.getNextToken()
					return ScriptObjectFactory.NewBool(False)

			End Select

			' Something different - possibly a function name or a property.

			' Switch off "ignore whitespace" as properties shouldn't contain spaces?
			Self._tokeniser.getNextToken()

			Local args:TList      = New TList
			Local isFunction:Byte = False

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

				While (Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN And Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_EOF)

					' Too many parameters.
					If currentArgument > parameterCount Then
						RuntimeError("Function ~q" + functionOrPropertyName + "~q -- Too many parameters")
					EndIf

					' Only parse if we have parameters.
					If parameterCount > 0 Then

						' Get the next parameter.
						Local beforeArg:Int  = Self._tokeniser.currentPosition
						Local e:ScriptObject = Self.parseExpression()
						Local afterArg:Int   = Self._tokeniser.currentPosition

						' Evaluate (will skip in parse only mode)
						If self._evalMode <> MODE_PARSE_ONLY Then
							' Convert to the required param & add to the list of params
''							Local convertedValue:ScriptObject = e

							' TODO: Add this as a script object instead?
							args.AddLast(e.ToString())
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

				' Not enough parameters.
				If currentArgument < parameterCount Then
					RuntimeError("Function ~q" + functionOrPropertyName + "~q -- Not enough parameters")
				EndIf

				' No close bracket found.
				If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
					RuntimeError("')' expected at " + self._tokeniser.currentPosition)
				EndIf

				Self._tokeniser.getNextToken()

			EndIf

			' Either run a function or get a property value
			If self._evalMode <> MODE_PARSE_ONLY Then
				If isFunction
					Return Self.evaluateFunction(functionOrPropertyName, args)
				Else
					Return Self.evaluateProperty(functionOrPropertyName)
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
		Local func:SimpleExpressions_Function = Self.getFunction(functionName)

		' TODO: Throw a proper exception here.
		If func = Null Then Throw "No handler found for function '" + functionName + "'"

		Return func.execute(argList)
	End Method

	Method evaluateProperty:ScriptObject(propertyName:String)
		Return Self.getProperty(propertyName)
	End Method


	' ------------------------------------------------------------
	' -- Internal script stuff
	' ------------------------------------------------------------

	Method getFunction:SimpleExpressions_Function(name:String)
		Return SimpleExpressions_Function(Self._registeredFunctions.valueForKey(name))
	End Method

	' TODO: This will need support for getting object fields eventually.
	Method getProperty:ScriptObject(name:String)
		Return ScriptObject(Self._properties.ValueForKey(name))
	End Method

	Method _countFunctionParameters:Int(functionName:String)
		Local func:SimpleExpressions_Function = SimpleExpressions_Function(Self._registeredFunctions.ValueForKey(functionName))
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
			Local set:FunctionSet = FunctionSet(setType.NewObject())

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

	' TODO: Remove this!'
	Function Create:ExpressionEvaluator(expression:String)

		Local this:ExpressionEvaluator = New ExpressionEvaluator
		this.setExpression(expression)
		Return this

	End Function

	Method New()
		Self._tokeniser           = New ExpressionTokeniser
		Self._registeredFunctions = New TMap
		Self._properties          = New TMap
		Self._evalMode            = MODE_EVALUATE
	End Method

End Type
