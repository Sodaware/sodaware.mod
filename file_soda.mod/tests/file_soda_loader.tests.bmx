SuperStrict

Framework BaH.MaxUnit
import sodaware.file_soda

New TTestSuite.run()

Type Sodaware_FileSodaLoaderTests Extends TTest

	Field validFile:SodaFile

	Method setup() { before }
		Self.validFile	= SodaFile.Load("components.soda")
	End Method
	
	Method tearDown() { after }
		GCCollect()
	End Method

	Method loadsCorrectGroupCount() { test }
		Self.assertEqualsI(23, Self.validFile.countGroups())
	End Method
			
End Type