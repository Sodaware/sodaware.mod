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

	''' <summary>Set the expression to be used and reset the internal state.</summary>
	Method _setExpression(expression:String)
		Self._evalMode = MODE_EVALUATE
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
		Self._setExpression(expression)

		' Run the expression.
		Local result:ScriptObject = Self.parseExpression()

		' TODO: Wrap this in `tokeniser.isEof`
		If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_EOF Then
			Throw("Unexpected Char at end of expression: " + Self._tokeniser.currentToken)
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

		Local interpolatedValue:String = value
		While Instr(interpolatedValue, "${") > 0

			Local expression:String = Mid(interpolatedValue, Instr(interpolatedValue, "${") + 2, Instr(interpolatedValue, "}") - Instr(interpolatedValue, "${") - 2)

			If Instr(interpolatedValue, "}") < 1 Then
				Throw "Missing closing token in interpolated string ~q" + interpolatedValue + "~q"
			EndIf

			' If expression has contents, evaluate it.
			If expression <> "" Then

				' -- Execute
				Local res:ScriptObject = Self.evaluate(expression)
				If res = Null Then
					Print "Expression '" + expression + "' returned a null result"
				End If

				' -- Replace expression with value
				interpolatedValue = interpolatedValue.Replace("${" + expression + "}", res.ToString())
			Else
				interpolatedValue = interpolatedValue.Replace("${" + expression + "}", "")
			EndIf

		Wend

		Return interpolatedValue

	End Method


	' ------------------------------------------------------------
	' -- Evaluation Methods
	' ------------------------------------------------------------

	Method parseExpression:ScriptObject()

		Local leftSide:ScriptObject = Self.parseBooleanAnd()

		While Self._tokeniser.isKeyword("or")

			' If the left side is TRUE, we can skip evaluation because the
			' result will be TRUE.
			If leftSide.valueBool() Then Self._evalMode = MODE_PARSE_ONLY

			' Evaluate the rest of the expression.
			Self._tokeniser.getNextToken()
			Local rightSide:ScriptObject = self.parseBooleanAnd()

			If Self._evalMode <> MODE_PARSE_ONLY Then
				' TODO: Don't call `NewBool` here - use a helper to return one of the two private globals (to prevent creating lots of objects)
				leftSide = ScriptObjectFactory.NewBool(leftSide.valueBool() Or rightSide.valueBool())
			EndIf

		Wend

		Return leftSide

	End Method

	Method parseBooleanAnd:ScriptObject()

		Local leftSide:ScriptObject = Self.parseRelationalExpression()

		While Self._tokeniser.isKeyword("and")

			' If the left side is FALSE, we can skip evaluation because the
			' result will be FALSE.
			If leftSide.valueBool() = FALSE Then Self._evalMode = MODE_PARSE_ONLY

			' Evaluate the rest of the expression.
			Self._tokeniser.getNextToken()
			Local rightSide:ScriptObject = Self.parseRelationalExpression()

			If Self._evalMode <> MODE_PARSE_ONLY Then
				leftSide = ScriptObjectFactory.NewBool(leftSide.valueBool() And rightSide.valueBool())
			EndIf
		Wend

		Return leftSide

	End Method

	Method parseRelationalExpression:ScriptObject()

		Local leftSide:ScriptObject = Self.parseAddSubtract()

		If Self._tokeniser.isRelationalOperator() Then

			Local op:Byte = Self._tokeniser.currentToken
			Self._tokeniser.getNextToken()

			Local rightSide:ScriptObject = Self.parseAddSubtract()

			If Self._evalMode = MODE_PARSE_ONLY Then Return Null

			' TODO: Needs to support comparing strings, numbers and booleans.
			' TODO: Replace int casting with valueNumeric?
			' TODO: I don't think these work :)
			Select op

				' Equals operator
				Case ExpressionTokeniser.TOKEN_EQUAL
					Return ScriptObjectFactory.NewBool(leftSide.equals(rightSide))

				' Not equal to
				Case ExpressionTokeniser.TOKEN_NOT_EQUAL
					Return ScriptObjectFactory.NewBool(leftSide.notEquals(rightSide))

				Case ExpressionTokeniser.TOKEN_LT
					Return Self._bool(leftSide.lessThan(rightSide))

				Case ExpressionTokeniser.TOKEN_GT
					Return Self._bool(leftSide.greaterThan(rightSide))

				Case ExpressionTokeniser.TOKEN_LE
					Return ScriptObjectFactory.NewBool(Int(leftSide.ToString()) <= Int(rightSide.ToString()))

				Case ExpressionTokeniser.TOKEN_GE
					Return ScriptObjectFactory.NewBool(Int(leftSide.ToString()) >= Int(rightSide.ToString()))

			End Select

		EndIf

		Return leftSide

	End Method

	Method parseAddSubtract:ScriptObject()

		Local leftSide:ScriptObject  = Self.parseMulDiv()
		Local rightSide:ScriptObject = Null

		Repeat
			Select Self._tokeniser.currentToken

				' Addition.
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

					Self._tokeniser.getNextToken()
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

			End Select
		Forever

		Return leftSide

	End Method

	Method parseMulDiv:ScriptObject()

		Local leftSide:ScriptObject  = Self.parseValue()
		Local rightSide:ScriptObject = Null

		Repeat

			Select Self._tokeniser.currentToken

				Case ExpressionTokeniser.TOKEN_MUL
					Self._tokeniser.getNextToken()
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

	' TODO: This is ugly and pretty slow
	Method parseValue:ScriptObject()

		' -- Setup
		Local val:ScriptObject

		Select Self._tokeniser.currentToken

			' Plain number
			Case ExpressionTokeniser.TOKEN_NUMBER
				Local number:String = Self._tokeniser.tokenText

				Self._tokeniser.getNextToken()

				' Check for fractions
				If Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_DOT Then
					number = number + "."
					Self._tokeniser.getNextToken()

					' Check there's a number after the decimal point
					If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_NUMBER Then
						Self._throwSyntaxError()
					EndIf

					number = number + Self._tokeniser.tokenText

					Self._tokeniser.getNextToken()

					' Done
					Return ScriptObjectFactory.NewFloat(Float(number))

					' Integer
				Else
					Return ScriptObjectFactory.NewInt(Int(number))
				EndIf

			' Negative numbers.
			Case ExpressionTokeniser.TOKEN_MINUS
				Self._tokeniser.getNextToken()

				' Get the next value and then negate it.
				val	= Self.parseValue()

				If self._evalMode <> MODE_PARSE_ONLY Then
					' TODO: Can we optimize this?
					Return ScriptObject.SubtractObjects(ScriptObjectFactory.NewInt(0), val)
				EndIf

				Return Null

			' Items in brackets.
			Case ExpressionTokeniser.TOKEN_LEFT_PAREN
				Self._tokeniser.getNextToken()

				val	= Self.parseExpression()

				' Check for missing closed brackets.
				If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
					RuntimeError("')' expected at " + self._tokeniser.currentPosition)
				EndIf

				Self._tokeniser.getNextToken()
				Return val

			' In a string.
			Case ExpressionTokeniser.TOKEN_STRING
				val = ScriptObjectFactory.NewString(Self._tokeniser.tokenText)
				Self._tokeniser.getNextToken()
				Return val

			' NOT
			Case ExpressionTokeniser.TOKEN_NOT
				Self._tokeniser.getNextToken()
				val	= Self.parseValue()

				If self._evalMode <> MODE_PARSE_ONLY Then
					Return ScriptObjectFactory.NewBool(Not(val.valueBool()))
				EndIf

				Return Null

			' Keywords (could be a function or a variable)
			Case ExpressionTokeniser.TOKEN_KEYWORD
				Local functionOrPropertyName:String = Self._tokeniser.tokenText

				' Something different - possibly a function name or a property.

				' TODO: Switch off "ignore whitespace" as properties shouldn't contain spaces?
				Self._tokeniser.getNextToken()

				Local args:ScriptObject[]
				Local isFunction:Byte = False

				' TODO: Shouldn't require the double colon for property or function names.

				' Get the current property or function name
				If Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_DOUBLE_COLON Then

					' Function
					isFunction = True
					functionOrPropertyName = functionOrPropertyName + "::"
					Self._tokeniser.getNextToken()

					' Check the :: is followed by a keyword
					If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_KEYWORD Then
						RuntimeError("Function name expected")
					EndIf

					functionOrPropertyName = functionOrPropertyName + Self._tokeniser.tokenText
					Self._tokeniser.getNextToken()

				ElseIf Not CharHelper.isAsciiWhitespace(Self._tokeniser.currentToken) Then

					' Property
					' TODO: This is so ugly it hurts. Fix it.
					While(Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_DOT Or Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_MINUS Or Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_KEYWORD Or Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_NUMBER)
						functionOrPropertyName = functionOrPropertyName + Self._tokeniser.tokenText
						Self._tokeniser.getNextToken()
					Wend

				EndIf

				' Switch whitespace back on.
				Self._tokeniser.ignoreWhitespace = True

				' If we're at a space, get the next token.
				If Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_WHITESPACE Then
					Self._tokeniser.getNextToken()
				EndIf

				' Extract function arguments.
				If isFunction Then
					args = Self.parseFunctionArgs(functionOrPropertyName)
				EndIf

				' Either run a function or get a property value
				If self._evalMode = MODE_PARSE_ONLY Then Return Null

				If isFunction
					Return Self.evaluateFunction(functionOrPropertyName, args)
				Else
					Return Self.evaluateProperty(functionOrPropertyName)
				EndIf

		End Select

		Return val

	End Method

	Method parseFunctionArgs:ScriptObject[](functionName:String)

		' Check for opening bracket (for params)
		If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_LEFT_PAREN Then
			RuntimeError("'(' expected at " + self._tokeniser.currentPosition)
		EndIf

		Local currentArgument:Int = 0
		Local parameterCount:Int  = Self._countFunctionParameters(functionName)
		Local args:ScriptObject[parameterCount]

		' Move to start of arguments.
		Self._tokeniser.getNextToken()

		' If no parameters, just skip to the end.
		If parameterCount = 0 Then
			' TODO: Should probably check for a close parenthesis here.
			Self._tokeniser.getNextToken()
			Return args
		EndIf

		While (Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN And Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_EOF)

			' Check if too many parameters have been read.
			If currentArgument > parameterCount Then
				RuntimeError("Function ~q" + functionName + "~q -- Too many parameters (expected " + parameterCount + ")")
			EndIf

			' Get the next parameter.
			Local e:ScriptObject = Self.parseExpression()

			' Evaluate (will skip in parse only mode)
			If self._evalMode <> MODE_PARSE_ONLY Then
				args[currentArgument] = e
			EndIf

			currentArgument = currentArgument + 1

			' Check if we're at the end
			If Self._tokeniser.currentToken = ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
				Exit
			EndIf

			' Check if there was no comma (syntax error)
			If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_COMMA Then
				RuntimeError("',' expected at " + Self._tokeniser.currentPosition + " -- found " + Self._tokeniser.currentToken)
			EndIf

			Self._tokeniser.getNextToken()

		Wend

		' Not enough parameters.
		If currentArgument < parameterCount Then
			RuntimeError("Function ~q" + functionName + "~q -- Not enough parameters")
		EndIf

		' No close bracket found.
		If Self._tokeniser.currentToken <> ExpressionTokeniser.TOKEN_RIGHT_PAREN Then
			RuntimeError("')' expected at " + self._tokeniser.currentPosition)
		EndIf

		Self._tokeniser.getNextToken()

		return args

	End Method

	Method evaluateFunction:ScriptObject(functionName:String, argList:ScriptObject[] = Null)
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
		Local func:SimpleExpressions_Function = Self.getFunction(functionName)
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
	''' <summary>Convert BlitzMax true/false into compatible boolean values.</summary>
	Method _bool:ScriptObject(result:Int)
		Select result
			case True  ; Return Expression_Evaluator_True
			Case False ; Return Expression_Evaluator_False
		End Select
	End Method

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

	Method New()
		Self._tokeniser           = New ExpressionTokeniser
		Self._registeredFunctions = New TMap
		Self._properties          = New TMap
		Self._evalMode            = MODE_EVALUATE

		' Add false + true as properties.
		Self._properties.Insert("true",  Expression_Evaluator_True)
		Self._properties.Insert("false", Expression_Evaluator_False)
	End Method

End Type

Private

' Create true and false as globals so they don't have to be re-created when
' building a new evaluator.
Global Expression_Evaluator_True:ScriptObject  = ScriptObjectFactory.NewBool(True)
Global Expression_Evaluator_False:ScriptObject = ScriptObjectFactory.NewBool(False)

Public
