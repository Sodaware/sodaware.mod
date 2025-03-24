SuperStrict

Framework BaH.MaxUnit
Import sodaware.blitzmax_string

New TTestSuite.run()

Type Sodaware_BlitzMax_String_FunctionTests Extends TTest
	
	Method CanSplitStringTest() { test }
		
		Local testString:String = "one,two,three"
		Local result:String[]   = string_split(testString)
		
		Self.assertEqualsI(3, result.Length)
		
		Self.assertEquals("one", result[0])
		Self.assertEquals("two", result[1])
		Self.assertEquals("three", result[2])
		
	End Method
	
	Method CanSplitStringWithoutDelimiterTest() { test }
		
		Local testString:String = "one"
		Local result:String[]   = string_split(testString)
		
		Self.assertEqualsI(1, result.Length)
		
		Self.assertEquals("one", result[0])
		
	End Method

	Method CanSplitQuotedStringWithoutDelimiterTest() { test }
		
		Local testString:String = "'one,two'"
		Local result:String[]   = string_split(testString)
		
		Self.assertEqualsI(1, result.Length)
		
		Self.assertEquals("one,two", result[0])
		
	End Method

	
	Method CanSplitStringWithQuotesTest() { test }
	
		Local testString:String = "one,~qtwo,two~q,three"
		Local result:String[]   = string_split(testString)
		
		Self.assertEqualsI(3, result.length)
		
		Self.assertEquals("one", result[0])
		Self.assertEquals("two,two", result[1])
		Self.assertEquals("three", result[2])
		
	End Method

	Method CanSplitStringWithMixedQuotesTest() { test }
	
		Local testString:String = "one,~qtwo,'two',two~q,three"
		Local result:String[]   = string_split(testString)
		Self.assertEqualsI(3, result.Length)
		Self.assertEquals("one", result[0])
		Self.assertEquals("two,'two',two", result[1])
		Self.assertEquals("three", result[2])
	End Method
	
End Type