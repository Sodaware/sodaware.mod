SuperStrict

Framework BaH.MaxUnit
Import sodaware.file_soda

New TTestSuite.run()

Type Sodaware_FileSoda_SodaGroup_Tests Extends TTest

	Field validFile:SodaFile

	Method setup() { before }
		Self.validFile	= SodaFile.Load("valid_file.txt")
	End Method
	
	Method tearDown() { after }
		GCCollect()
	End Method
	
	Method loadString:SodaFile(data:String)
		Local stringData:TBank = TBank.create(data.length)
		For local i:int = 0 to data.length - 1
			stringData.pokebyte(i, data[i])
		Next
		Return SodaFile.Load(stringData)
	End Method


	' ------------------------------------------------------------
	' -- ->countFields
	' ------------------------------------------------------------

	Method testCountFieldsReturnsZeroForNewGroup() { test }
		Local group:SodaGroup = New SodaGroup
		Self.assertEqualsI(0, group.countFields())
	End Method

	Method testCountFieldsReturnsCorrectResultForStandardFields() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")
		group.addField("test_field2", "")

		Self.assertEqualsI(2, group.countFields())
	End Method

	Method testCountFieldsDoesNotDoubleCountDuplicateFieldNames() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")
		group.addField("test_field1", "")

		Self.assertEqualsI(1, group.countFields())
	End Method

	Method testCountFieldsDoesNotCountRemovedFields() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")
		group.addField("test_field2", "")
		Self.assertEqualsI(2, group.countFields())

		group.removeField("test_field1")
		Self.assertEqualsI(1, group.countFields())

		' Check if doesn't double count the removal.
		group.removeField("test_field1")
		Self.assertEqualsI(1, group.countFields())
	End Method

	Method testCountFieldsDoesNotDoubleCountRemovedFields() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")
		group.addField("test_field2", "")
		Self.assertEqualsI(2, group.countFields())

		group.removeField("test_field1")
		group.removeField("test_field1")
		Self.assertEqualsI(1, group.countFields())
	End Method

	
	' ------------------------------------------------------------
	' -- ->countChildren
	' ------------------------------------------------------------

	Method testCountChildrenReturnsZeroForNewGroup() { test }
		Local group:SodaGroup = New SodaGroup
		Self.assertEqualsI(0, group.countChildren())
	End Method


	' ------------------------------------------------------------
	' -- ->getFieldNames
	' ------------------------------------------------------------

	Method testGetFieldNamesReturnsEmptyListForNewGroup() { test }
		Local group:SodaGroup = New SodaGroup
		Self.assertEmpty(group.getFieldNames())
	End Method

	Method testGetFieldNamesReturnsListOfFieldNames() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")
		group.addField("test_field2", "")

		Self.assertEqualsI(2, group.getFieldNames().count())
		Self.assertContains("test_field1", group.getFieldNames())
		Self.assertContains("test_field2", group.getFieldNames())
	End Method

	Method testGetFieldNamesDoesNotContainDuplicates() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")
		group.addField("test_field1", "")

		Self.assertEqualsI(1, group.getFieldNames().count())
		Self.assertContains("test_field1", group.getFieldNames())
	End Method

	Method testGetFieldNamesDoesNotContainRemovedfields() { test }
		Local group:SodaGroup = New SodaGroup
		group.addField("test_field1", "")

		Self.assertContains("test_field1", group.getFieldNames())
		group.removeField("test_field1")
		Self.assertNotContains("test_field1", group.getFieldNames())
	End Method


	' ------------------------------------------------------------
	' -- Assertion Helpers
	' ------------------------------------------------------------

	Method assertEmpty(list:TList)
		Self.assertTrue(list.isEmpty())
	End Method

	Method assertNotEmpty(list:TList)
		Self.assertFalse(list.isEmpty())
	End Method

	Method assertContains(value:Object, list:TList)
		Self.assertTrue(list.contains(value))
	End Method

	Method assertNotContains(value:Object, list:TList)
		Self.assertFalse(list.contains(value))
	End Method

End Type