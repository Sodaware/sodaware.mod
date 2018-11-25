SuperStrict

Framework BaH.MaxUnit
import sodaware.file_soda

New TTestSuite.run()

Type Sodaware_FileSodaTests Extends TTest

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
	' -- Loading invalid files
	' ------------------------------------------------------------

	Method LoadInvalidFileMustReturnNullTest() { test }
		Self.assertNull(SodaFile.Load("some-file-that-doesn't-exist.txt"), "Did not return null!")
	End Method

	' This bug means it will fail loading a phpDoc style comment - check it's fixed
	Method CanCollapseMultiCommentWithDoubleStarsTest() { test }
		Local f:SodaFile = SodaFile.Load("multi-line-comment-test.txt")

		Self.assertNotNull(f, "Could not load file")
		Self.assertNotNull(f.Query("rules.interface.menu_images.icon_search"), "Could not find 'menu_images' group")
		Self.assertEqualsI(2, SodaGroup(f.Query("rules.interface.hover_effects")).GetChildren("*").count(), "Not enough contents")
	End Method

	' ------------------------------------------------------------
	' -- Meta data in identifiers
	' ------------------------------------------------------------

	Method GroupWithMetaInTitleTest() { test }
		Local file:SodaFile = SodaFile.Load("rules.soda")

		' Check loaded correctly
		Self.assertEqualsI(file.countGroups(), 5, "Loaded incorrect group count")

		' Check if identifier loaded correctly
		Self.assertEquals("rules", SodaGroup(file.getGroupAtIndex(0)).Identifier)
		Self.assertEquals("rarity_uncommon", SodaGroup(file.getGroupAtIndex(2)).Identifier)
		Self.assertEquals("rarity", SodaGroup(file.getGroupAtIndex(2)).getMeta("t"))

	End Method

	Method canLoadGroupMetaDataWithSpacesTest() { test }
		Local file:SodaFile = self.loadString("[t:something,  n:something_else] { }")
		self.assertNotNull(file)
		self.assertEqualsI(1, file.countGroups())
		Local g:SodaGroup = file.GetGroup("something_else")
		self.assertNotNull(g)
		self.assertEquals("something_else", g.getIdentifier())
		self.assertEquals("something", g.getMeta("t"))
	End Method

	Method canLoadGroupMetaDataWithoutSpaceTest() { test }
		Local file:SodaFile = self.loadString("[t:something,n:something_else] { }")
		self.assertNotNull(file)
		self.assertEqualsI(1, file.countGroups())
		Local g:SodaGroup = file.GetGroup("something_else")
		self.assertNotNull(g)
		self.assertEquals("something_else", g.getIdentifier())
		self.assertEquals("something", g.getMeta("t"))
	End Method

	Method canLoadGroupMetaDataWithSemiColonTest() { test }
		Local file:SodaFile = self.loadString("[t:something; n:something_else] { }")
		self.assertNotNull(file)
		self.assertEqualsI(1, file.countGroups())
		Local g:SodaGroup = file.GetGroup("something_else")
		self.assertNotNull(g)
		self.assertEquals("something_else", g.getIdentifier())
		self.assertEquals("something", g.getMeta("t"))
	End Method

	Method GetGroupByMetaDataTest() { test }
		Local file:SodaFile = SodaFile.Load("rules.soda")
		Self.assertNotNull(file.GetNodes("[t:rarity]"), "Get nodes failed - no results found")
		Self.assertEqualsI(4, file.GetNodes("[t:rarity]").Count(), "Get nodes failed - Incorrect number of results found")
		Self.assertEqualsI(1, file.GetNodes("[n:rarity_rare, t:rarity]").Count(), "Get nodes failed - Incorrect number of results found")
	End Method

	Method ShorthandFieldtest() { test }
		Self.assertNull(Self.validFile.Query("group_two.empty_group:field_name"), "Should not accept : in field names")
		Self.assertEquals("Test value 1", Self.validFile.Query("group_two.empty_group.field_name1"), "Shorthand syntax did not work")
	End Method

	Method ShorthandFieldsShouldNotCreateDuplicateGroupsTest() { test }

		' Count groups
		Local testGroup:SodaGroup = Self.validFile.GetGroup("group_two")
		Self.assertEqualsI(2, testGroup.CountChildren(), "Duplicate groups created")
	End Method


	' ------------------------------------------------------------
	' -- Public API
	' ------------------------------------------------------------

	Method MustCountFieldsTest() { test }
		Self.assertEqualsI(1, Self.validFile.GetGroup("group_two").CountFields())
	End Method

	' ------------------------------------------------------------
	' -- Querying
	' ------------------------------------------------------------


	Method InvalidQueryBoolTest() { test }
		Self.assertFalse(Self.validFile.QueryBool(Null))
		Self.assertFalse(Self.validFile.QueryBool(""))
		Self.assertFalse(Self.validFile.QueryBool("."))
		Self.assertFalse(Self.validFile.QueryBool("....."))
	End Method

	Method InvalidQueryIntTest() { test }
		Self.assertEqualsI(0, Self.validFile.QueryInt(Null))
		Self.assertEqualsI(0, Self.validFile.QueryInt(""))
		Self.assertEqualsI(0, Self.validFile.QueryInt("."))
		Self.assertEqualsI(0, Self.validFile.QueryInt("....."))
	End Method

	Method InvalidQueryTest() { test }
		self.assertNull(Self.validFile.Query(null))
		self.assertNull(Self.validFile.Query(""))
		self.assertNull(Self.validFile.Query("."))
		self.assertNull(Self.validFile.Query("....."))
	End Method

	Method QueryHelperTest() { test }
		Local fileIn:SodaFile = SodaFile.Load("array_file.txt")
		Self.assertEqualsI(180, fileIn.QueryInt("skill[0].max_level"))
		Self.assertEqualsF(0.25, fileIn.Queryfloat("skill[0].str_influence"))
		Self.assertEqualsF(0.73, fileIn.Queryfloat("skill[1].int_influence"))
	End Method

	Method GetInvalidGroupTest() { test }
		self.assertNull(Self.validFile.Query("invalidGroup.invalidVariable"))
	End Method

	Method GetInvalidVariableTest() { test }
		self.assertNull(Self.validFile.Query("group.invalidVariable"))
	End Method

	Method GetValidVariableTest() { test }
		self.assertEquals("value", string( Self.validFile.Query("group.variable1")))
	End Method

	Method GetValidArrayTest() { test }
		Local fileIn:SodaFile = SodaFile.Load("array_file.txt")
		Local arr:TList = TList(fileIn.Query("content_db.file"))

		Self.assertNotNull(arr, "Could not create List")
		Self.assertEqualsI(2, arr.Count(), "Incorrect size returned")
		Self.assertEquals("story://content_db/armour.ini", arr.ValueAtIndex(1))
	End Method

	Method GetValidGroupTest() { test }
		Self.assertNotNull(Self.validFile.Query("group_two.sub_group"), "Couldn't find valid group")
	End Method

'	Method GetValidGroupArrayTest() { test }

	'	Local fileIn:SodaFile = SodaFile.Load("array_file.txt")
	'	Local arr:TList = TList(fileIn.Query("content_db.file"))

'	End Method


	Method GetNameTest() { test }
		Self.assertEquals("my_name", SodaFile_Util.getName("my_name"))
		Self.assertEquals("my_name", SodaFile_Util.getName("my_name[1]"))
	End Method

	Method GetOffsetTest() { test }
		Self.assertEqualsI(-2, SodaFile_Util.getOffset("my_name"))
		Self.assertEqualsI(12, SodaFile_Util.getOffset("my_name[12]"))
		Self.assertEqualsI(-2, SodaFile_Util.getOffset("my_name[-3]"))
	End Method

	Method QueryInvalidGroup() { test }
		Self.assertNull(Self.validFile.Query("group.test_variable"), "Query should return null for invalid field")
	End Method

	Method QueryWithOffsetTest() { test }
		Local fileIn:SodaFile = SodaFile.Load("array_file.txt")
		Self.assertEquals("story://content_db/weapons.ini", fileIn.query("content_db.file[0]"))
		Self.assertEquals("story://content_db/armour.ini", fileIn.query("content_db.file[1]"))
		Self.assertNull(fileIn.query("content_db.file[2]"))
	End Method

	Method QueryGroupWithOffsetTest() { test }
		Local fileIn:SodaFile = SodaFile.Load("array_file.txt")
		Self.assertNull(fileIn.Query("skill[-1].name"), "Found group at negative offset")
		Self.assertNull(fileIn.Query("skill[100].name"), "Found group outside of range")
		Self.assertNull(fileIn.Query("skill[1].level_up_indicator[-1].level_range"), "Found sub group at negative offset")
		Self.assertNull(fileIn.Query("skill[1].level_up_indicator[6].level_range"), "Found sub group outside of range")
		Self.assertNull(fileIn.Query("skill[1].level_up_indicator[1].sdfsdf"), "found invalid field")
	End Method

	Method QueryGroupWithValidOffsetTest() { test }
		Local fileIn:SodaFile = SodaFile.Load("array_file.txt")
		Self.assertEquals("Ranged", fileIn.Query("skill[0].name"))
		Self.assertEquals("Nature Magic", fileIn.Query("skill[1].name"))
		Self.assertEquals("11-20", fileIn.Query("skill[1].level_up_indicator[2].level_range"))
	End Method

'	Method IncludeFileTest() { test }
'		Local fileIn:SodaFile = SodaFile.Load("include_test.txt")
'		Self.assertEquals("value", fileIn.Query("group.variable1"))
'		Self.assertNull(fileIn.Query("group1.variable1"))
'	End Method

	' ------------------------------------------------------------
	' -- Set values test
	' ------------------------------------------------------------

	Method SetValueTest() { test }
		Self.assertNull(Self.validFile.Query("group.test_variable"), "Should not find variable before add")
		Self.validFile.SetValue("group.test_variable", "test_value")
		Self.assertEquals("test_value", Self.validFile.Query("group.test_variable"), "Didn't add correctly")
	End Method

	Method SetValueWithNonExistantGroupTest() { test }
		Self.assertNull(Self.validFile.Query("new_group.test_variable"), "Should not find variable before add")
		Self.validFile.SetValue("new_group.test_variable", "test_value")
		Self.assertEquals("test_value", Self.validFile.Query("new_group.test_variable"), "Didn't add correctly")
	End Method

'	Method SetValueWithNonExistantGroupTreeTest()
'		Self.assertNull(Self.validFile.Query("new_group1.new_group2.test_variable"), "Should not find variable before add")
'		Self.validFile.SetValue("new_group1.new_group2.test_variable", "test_value")
'		Self.assertEquals("test_value", Self.validFile.Query("new_group1.new_group2.test_variable"), "Didn't add correctly")
'	End Method

	' ------------------------------------------------------------
	' -- Internal API
	' ------------------------------------------------------------

	Method GetGroupNameTest() { test }
		Self.assertEquals("group_name", SodaFile._getGroupName("group_name.field_name"), "Incorrect group name returned")
	End Method


	Method GetFieldNameTest() { test }
		Self.assertEquals("field_name", SodaFile._getFieldName("group_name.field_name"), "Incorrect field name returned")
	End Method

End Type