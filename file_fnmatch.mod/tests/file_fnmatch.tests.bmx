SuperStrict

Framework BaH.MaxUnit
Import sodaware.file_fnmatch

' run the tests!
New TTestSuite.run()

Type Sodaware_File_FnMatchTests Extends TTest

	Method AsteriskTest() { test }
		Self.assertTrue(fnmatch("my_file.bmx", "*.bmx"), "Did not match file extension")
		Self.assertTrue(fnmatch("tests/super/test.bmx", "tests/*/*.bmx"), "Did not match file extension in directory")
		Self.assertTrue(fnmatch("../tests/controller.tests.bmx", "*.tests.bmx"), "Pattern should match")
	End Method

	Method MatchWholeStringTest() { test }
		Self.assertTrue(fnmatch("my_file.bmx", "*"))
	End Method

	Method SimplePatternTest() { test }
		Self.assertFalse(fnmatch("tests/client\test", "*.tests.bmx"), "Incorrect pattern match")
	End Method

	Method SingleCharacterTest() { test }
		Self.assertTrue(fnmatch("test.bmx", "te?t.bmx"), "Incorrect pattern match")
		Self.assertTrue(fnmatch("text.bmx", "te?t.bmx"), "Incorrect pattern match")
	End Method

	Method MultipleAsterisksTest() { test }
		Self.assertTrue(fnmatch("directory_here/name.txt", "directory_here/***.txt"), "Should match")
		Self.assertTrue(fnmatch("directory_here/name.txt", "directory_here/*.txt"), "Should match")
		Self.assertFalse(fnmatch("directory_here/name.txt", "directory_here/***.ext"), "Should not match")
	End Method

	Method WildcardAtEndOfStringTest() { test }
		Self.assertFalse(fnmatch("directory_here/", "directory_here/*.txt"), "Should not match")
	End Method

	Method longFilenameTest() { test }
		Self.assertTrue(fnmatch("D:\Program Files\BlitzMax\mod\sodaware.mod\file_fnmatch.mod\.bmx\file_fnmatch.tests.bmx.console.debug.mt.win32.x86.o", "*.o"), "Did not match but should")
	End Method

	Method AsteriskShouldMatchNestedExtensionTest() { test }
		Self.assertTrue(fnmatch("path/directory_here/Thumbs.db", "*.db"), "Asterisk should match all the way to the end")
	End Method

	Method MatchAnyPartTest() { test }
		Self.assertTrue(fnmatch("Thumbs.db", "Thumbs.db"), "Should match if only string")
		Self.assertTrue(fnmatch("directory_here/Thumbs.db", "*Thumbs.db"), "Should match if at end")
	End Method

End Type
