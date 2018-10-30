SuperStrict

Framework BaH.MaxUnit

Import sodaware.BlitzMax_Debug
Import sodaware.simple_expressions

New TTestSuite.run()

Type BlitzBuild_Expressions_ExpressionEvaluatorTests Extends TTest

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
	' -- Number Tests
	' ------------------------------------------------------------

	Method testCanAddIntegers() { test }
		Self._testExpressionI(3, "1 + 2")
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


	' ------------------------------------------------------------
	' -- String Tests
	' ------------------------------------------------------------

	Method testCanConcatenateStrings() { test }
		Self._testExpression("hellogoodbye", "'hello' + 'goodbye'")
	End Method

	Method testCanConcatenateStringsAndNumbers() { test }
		Self._testExpression("hellogoodbye3", "'hello' + 'goodbye' + 3")
	End Method


''	Method SimpleFunctionTest() { test }
''		Local eval:ExpressionEvaluator = ExpressionEvaluator.Create("namespace::function()")
''		Local func:ScriptFunction = New ScriptFunction
''		func.m_FullName= "namespace::function"
''		eval.RegisterFunction(func)
''		Local res:ScriptObject = eval.Evaluate()
''		Self.assertEquals("20", res.ValueString(), ":(")
''	End Method


	' ------------------------------------------------------------
	' -- Property Tests
	' ------------------------------------------------------------

	Method testCanReplaceSingleProperty() { test }
		Local eval:ExpressionEvaluator = ExpressionEvaluator.Create("myProp" )
		eval.RegisterStringProperty("myProp", "hello")
		Local res:ScriptObject = eval.Evaluate()
		Self.assertEquals("hello", res.ValueString())
	End Method

	Method testCanAddProperties() { test }
		Local eval:ExpressionEvaluator = ExpressionEvaluator.Create("myProp + ' there!' + (2 + some_number)" )
		eval.RegisterStringProperty("myProp", "hello")
		eval.RegisterIntProperty("some_number", 12)
		Local res:ScriptObject = eval.Evaluate()
		Self.assertEquals("hello there!14", res.ValueString())
	End Method


	' ------------------------------------------------------------
	' -- Internal Helpers
	' ------------------------------------------------------------

	' Internal helper - test an expression evaluations to a specific integer value
	Method _testExpressionI(expected:Int, expression:String, message:String = "")
		Local eval:ExpressionEvaluator = ExpressionEvaluator.Create(expression)
		Local res:ScriptObject = eval.Evaluate()
		Self.assertEqualsI(expected, res.ValueInt(), message)
	End Method

	' Internal helper - test an expression evaluations to a specific string
	Method _testExpression(expected:String, expression:String, message:String = "")
		Local eval:ExpressionEvaluator = ExpressionEvaluator.Create(expression)
		Local res:ScriptObject = eval.Evaluate()
		Self.assertEquals(expected, res.ValueString(), message)
	End Method

End Type


Private

Type FunctionTest Extends ScriptFunction
	Method New()
		Self._fullName = "namespace::my-func"
	End Method

	Method Execute:ScriptObject()
		Return ScriptObjectFactory.NewInt(20)
	End Method

End Type

Public