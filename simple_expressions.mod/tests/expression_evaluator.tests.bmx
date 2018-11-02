SuperStrict

Framework BaH.MaxUnit

Import sodaware.BlitzMax_Debug
Import sodaware.simple_expressions

New TTestSuite.run()

Type BlitzBuild_Expressions_ExpressionEvaluatorTests Extends TTest

	Field _evaluator:ExpressionEvaluator

	Method setUp() { before }
		Self._evaluator = New ExpressionEvaluator
	End Method


	' ------------------------------------------------------------
	' -- Evaluation Tests
	' ------------------------------------------------------------

	Method testCanQuickEvaluateValidExpression() { test }
		Self.assertEqualsI(2, ExpressionEvaluator.quickEvaluate("(10 + 4) / 7").valueInt())
	End Method

	Method textQuickEvaluateWithInvalidExpressionThrowsException() { test }

		Try
			ExpressionEvaluator.QuickEvaluate("(10 + 4) / ")
			Self.assertNotNull(Null, "Test failed to throw exception")
		Catch e:Object
			Self.assertEquals("Syntax error in expression: + ~q" + "(10 + 4) / " + "~q", e.ToString(), "Must throw exception if expression is invalid")
		End Try

	End Method


	' ------------------------------------------------------------
	' -- Interpolation Tests
	' ------------------------------------------------------------

	Method testInterpolateDoesNotProcessEmptyString() { test }
		Self.assertEquals("", Self._evaluator.interpolate(""))
	End Method

	Method testInterpolateDoesNotProcessStringWithoutExpressions() { test }
		Self.assertEquals("hello there", Self._evaluator.interpolate("hello there"))
		Self.assertEquals("1 + 1", Self._evaluator.interpolate("1 + 1"))
	End Method

	Method testInterpolateProcessesSingleString() { test }
		Self.assertEquals("2", Self._evaluator.interpolate("${1 + 1}"))
	End Method

	Method testInterpolateProcessesMultipleStrings() { test }
		Self.assertEquals("2 > 1", Self._evaluator.interpolate("${1 + 1} > ${2 - 1}"))
	End Method

	Method testInterpolateIgnoresWhitespace() { test }
		Self.assertEquals("2", Self._evaluator.interpolate("${   1 + 1   }"))
	End Method


	' ------------------------------------------------------------
	' -- Number Tests
	' ------------------------------------------------------------

	Method testCanReadIntegers() { test }
		Self._testExpressionI(3, "3")
		Self._testExpressionI(3, "  3  ")
		Self._testExpressionI(123456, "123456")
		Self._testExpressionI(123456, " 123456  ")
	End Method

	Method testCanReadNegativeIntegers() { test }
		Self._testExpressionI(-3, "-3")
		Self._testExpressionI(-3, "  -3  ")
		Self._testExpressionI(-123456, "-123456")
		Self._testExpressionI(-123456, " -123456  ")
	End Method

	Method testCanAddIntegers() { test }
		Self._testExpressionI(3, "1 + 2")
		Self._testExpressionI(15, "1 + 2 + 3 + 4 + 5")
	End Method

	Method testCanAddNegativeIntegers() { test }
		Self._testExpressionI(2, "3 + -1")
		Self._testExpressionI(-6, "-3 + -3")
	End Method

	Method testCanSubtractIntegers() { test }
		Self._testExpressionI(2, "4 - 2")
	End Method

	Method testCanMultiplyIntegers() { test }
		Self._testExpressionI(8, "4 * 2")
	End Method

	Method testCanDivideIntegers() { test }
		Self._testExpressionI(2, "4 / 2")
	End Method

	Method testEvaluatorObeysBrackets() { test }
		Self._testExpressionI(60, "10 * ( ( 4 / 2 ) + 4 )")
	End Method

	Method testCanAddFloats() { test }
		Self._testExpressionF(3.5, "1.75 + 1.75")
	End Method

	Method testCanSubtractFloats() { test }
		Self._testExpressionF(1.5, "2.75 - 1.25")
	End Method

	Method testCanMultiplyFloats() { test }
		Self._testExpressionF(6.25, "2.5 * 2.5")
	End Method

	Method testCanDivideFloats() { test }
		Self._testExpressionF(2.5, "6.25 / 2.5")
	End Method


	' ------------------------------------------------------------
	' -- String Tests
	' ------------------------------------------------------------

	Method testCanConcatenateStrings() { test }
		Self._testExpression("hellogoodbye", "'hello' + 'goodbye'")
	End Method

	Method testCanConcatenateStringsAndNumbers() { test }
		Self._testExpression("hellogoodbye3", "'hello' + 'goodbye' + 3")
	End Method


	' ------------------------------------------------------------
	' -- Logic Tests
	' ------------------------------------------------------------

	Method testOrReturnsCorrectResultForSimpleBooleans() { test }
		Self._testExpressionBool(True, "true or true")
		Self._testExpressionBool(True, "true or false")
		Self._testExpressionBool(True, "false or true")
		Self._testExpressionBool(False, "false or false")
	End Method

	Method testAndReturnsCorrectResultForSimpleBooleans() { test }
		Self._testExpressionBool(True, "true and true")
		Self._testExpressionBool(False, "true and false")
		Self._testExpressionBool(False, "false and true")
		Self._testExpressionBool(False, "false and false")
	End Method

	Method testMixedBooleansReturnCorrectResults() { test }
		Self._testExpressionBool(True, "true and true and true")
		Self._testExpressionBool(False, "true and true and false")
		Self._testExpressionBool(True, "true and true or false")
	End Method


	' ------------------------------------------------------------
	' -- NOT
	' ------------------------------------------------------------

	Method testNotConvertsBooleansCorrectly() { test }
		Self._testExpressionBool(False, "not true")
		Self._testExpressionBool(True, "not false")
	End Method

	Method testNotAcceptsExclamationShortcode() { test }
		Self._testExpressionBool(False, "!true")
		Self._testExpressionBool(True, "!false")
		Self._testExpressionBool(False, "! true")
		Self._testExpressionBool(True, "! false")
	End Method


	' ------------------------------------------------------------
	' -- Equality
	' ------------------------------------------------------------

	Method testEqualityCanAcceptBooleanValues() { test }
		Self._testExpressionBool(True, "true == true")
		Self._testExpressionBool(False, "true == false")
		Self._testExpressionBool(False, "false == true")
		Self._testExpressionBool(True, "false == false")
	End Method

	Method testEqualityCanAcceptIntegerValues() { test }
		Self._testExpressionBool(True, "1 == 1")
		Self._testExpressionBool(False, "1 == 0")
		Self._testExpressionBool(False, "0 == 1")
		Self._testExpressionBool(True, "0 == 0")
	End Method

	Method testEqualityCanAcceptFloatingPointValues() { test }
		Self._testExpressionBool(True, "1.0 == 1.0")
		Self._testExpressionBool(False, "1.0 == 0.0")
		Self._testExpressionBool(False, "0.0 == 1.0")
		Self._testExpressionBool(True, "0.0 == 0.0")
	End Method

	Method testEqualityCanAcceptStringValues() { test }
		Self._testExpressionBool(True, "'yes' == 'yes'")
		Self._testExpressionBool(False, "'yes' == 'no'")
		Self._testExpressionBool(False, "'no' == 'yes'")
		Self._testExpressionBool(True, "'no' == 'no'")
	End Method

	Method testEqualityCanAcceptPropertyValues() { test }
		Self._evaluator.registerIntProperty("value_1", 1)
		Self._testExpressionBool(True, "1 == value_1")

		Self._evaluator.registerStringProperty("value_two", "two")
		Self._testExpressionBool(True, "'two' == value_two")
	End Method


	' ------------------------------------------------------------
	' -- Not Equals
	' ------------------------------------------------------------

	Method testNotEqualAcceptsCStyleSyntax() { test }
		Self._testExpressionBool(False, "true != true")
		Self._testExpressionBool(True, "true != false")
		Self._testExpressionBool(True, "false != true")
		Self._testExpressionBool(False, "false != false")
	End Method

	Method testNotEqualAcceptsBasicStyleSyntax() { test }
		Self._testExpressionBool(False, "true <> true")
		Self._testExpressionBool(True, "true <> false")
		Self._testExpressionBool(True, "false <> true")
		Self._testExpressionBool(False, "false <> false")
	End Method

	Method testNotEqualAcceptsIntegers() { test }
		Self._testExpressionBool(False, "2 <> 2")
		Self._testExpressionBool(True, "2 <> 1")
		Self._testExpressionBool(True, "1 <> 2")
		Self._testExpressionBool(False, "1 <> 1")
	End Method

	Method testNotEqualAcceptsFloats() { test }
		Self._testExpressionBool(False, "2.5 <> 2.5")
		Self._testExpressionBool(True, "2.5 <> 1.5")
		Self._testExpressionBool(True, "1.5 <> 2.5")
		Self._testExpressionBool(False, "1.5 <> 1.5")
	End Method

	Method testNotEqualAcceptsStrings() { test }
		Self._testExpressionBool(False, "'two' <> 'two'")
		Self._testExpressionBool(True, "'two' <> 'one'")
		Self._testExpressionBool(True, "'one' <> 'two'")
		Self._testExpressionBool(False, "'one' <> 'one'")
	End Method

	' ------------------------------------------------------------
	' -- Not Equals
	' ------------------------------------------------------------

	Method testGreaterThanAcceptsBooleans() { test }
		Self._testExpressionBool(False, "true > true")
		Self._testExpressionBool(True, "true > false")
		Self._testExpressionBool(False, "false > true")
		Self._testExpressionBool(False, "false > false")
	End Method

	Method testGreaterThanAcceptsIntegers() { test }
		Self._testExpressionBool(False, "2 > 2")
		Self._testExpressionBool(True, "2 > 1")
		Self._testExpressionBool(False, "1 > 2")
		Self._testExpressionBool(False, "1 > 1")
	End Method

	Method testGreaterThanAcceptsFloats() { test }
		Self._testExpressionBool(False, "2.5 > 2.5")
		Self._testExpressionBool(True, "2.5 > 1.5")
		Self._testExpressionBool(False, "1.5 > 2.5")
		Self._testExpressionBool(False, "1.5 > 1.5")
	End Method

	Method testGreaterThanAcceptsStrings() { test }
		Self._testExpressionBool(False, "'two' > 'two'")
		Self._testExpressionBool(True, "'two' > 'one'")
		Self._testExpressionBool(False, "'one' > 'two'")
		Self._testExpressionBool(False, "'one' > 'one'")
	End Method
	

	' ------------------------------------------------------------
	' -- Custom Function Tests
	' ------------------------------------------------------------

	' TODO: Test that functions can be registered.

	Method testCustomScriptFunctionsCanBeCalled() { test }
		Local eval:ExpressionEvaluator = New ExpressionEvaluator
		eval.registerFunction(New FunctionTest)
		Local res:ScriptObject = eval.evaluate("test::simple-function()")
		Self.assertEqualsI(20, res.ValueInt())
	End Method

	Method testCustomScriptFunctionsCanEvaluateParameters() { test }
		Local eval:ExpressionEvaluator = New ExpressionEvaluator
		eval.registerFunction(New AddFunctionTest)
		Local res:ScriptObject = eval.evaluate("test::add(1 + 1, 2 + 2)")
		Self.assertEqualsI(6, res.ValueInt())
	End Method


	' ------------------------------------------------------------
	' -- Property Tests
	' ------------------------------------------------------------

	Method testCanReplaceSingleProperty() { test }
		Local eval:ExpressionEvaluator = New ExpressionEvaluator
		eval.RegisterStringProperty("myProp", "hello")
		Local res:ScriptObject = eval.Evaluate("myProp")
		Self.assertEquals("hello", res.ValueString())
	End Method

	Method testCanAddProperties() { test }
		Local eval:ExpressionEvaluator = New ExpressionEvaluator
		eval.RegisterStringProperty("myProp", "hello")
		eval.RegisterIntProperty("some_number", 12)
		Local res:ScriptObject = eval.evaluate("myProp + ' there!' + (2 + some_number)")
		Self.assertEquals("hello there!14", res.ValueString())
	End Method


	' ------------------------------------------------------------
	' -- Internal Helpers
	' ------------------------------------------------------------

	' Internal helper - test an expression evaluations to a specific integer value
	Method _testExpressionI(expected:Int, expression:String, message:String = "")
		Local eval:ExpressionEvaluator = New ExpressionEvaluator
		Local res:ScriptObject = eval.Evaluate(expression)
		Self.assertEqualsI(expected, res.ValueInt(), message)
	End Method

	Method _testExpressionF(expected:Float, expression:String, message:String = "")
		Local eval:ExpressionEvaluator = New ExpressionEvaluator
		Local res:ScriptObject = eval.Evaluate(expression)
		Self.assertEqualsF(expected, res.valueFloat(), 0, message)
	End Method

	' Internal helper - test an expression evaluations to a specific string
	Method _testExpression(expected:String, expression:String, message:String = "")
		Local res:ScriptObject = Self._evaluator.evaluate(expression)
		Self.assertEquals(expected, res.ValueString(), message)
	End Method

	' Internal helper - test an expression evaluations to a boolean
	Method _testExpressionBool(expected:Byte, expression:String, message:String = "")
		Local res:ScriptObject = Self._evaluator.evaluate(expression)

		If res = Null Then Throw expression
		If message = "" Then message = "`" + expression + "`"

		If expected Then
			self.assertTrue(res.valueBool(), message)
		Else
			self.assertFalse(res.valueBool(), message)
		EndIf

	End Method

End Type


Private

Type FunctionTest Extends SimpleExpressions_Function
	Method New()
		Self._fullName       = "test::simple-function"
		Self._parameterCount = 0
	End Method

	Method execute:ScriptObject(args:ScriptObject[])
		Return ScriptObjectFactory.NewInt(20)
	End Method
End Type

Type AddFunctionTest Extends SimpleExpressions_Function
	Method New()
		Self._fullName       = "test::add"
		Self._parameterCount = 2
	End Method

	Method execute:ScriptObject(args:ScriptObject[])
		Return ScriptObjectFactory.NewInt( ..
			args[0].valueInt() + ..
			args[1].valueInt() ..
		)
	End Method
End Type


Public
