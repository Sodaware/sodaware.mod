' ------------------------------------------------------------------------------
' -- src/soda_file_util.bmx
' --
' -- Utility functions for working with Soda files.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict
Import brl.retro

Type SodaFile_Util

	' ------------------------------------------------------------
	' -- Private stuff
	' ------------------------------------------------------------

	Function GetName:String(ident:String)
		If Instr(ident, "[") < 1 Then Return ident		
		Return Left(ident, Instr(ident, "[") - 1)
	End Function
	
	Function GetOffset:Int(ident:String)
		If Instr(ident, "[") < 1 Then Return -2
		Local offset:Int = Int(Mid(ident, Instr(ident, "[") + 1, Instr(ident, "]") - Instr(ident, "[") - 1))
		If offset < 0 Then offset = -2
		Return offset
	End Function
	
	Function HasOffset:Int(ident:String)
		Return (Instr(ident, "[") > 0)
	End Function
	
	Function AssembleQuery:String(parts:String[])
		Local qry:String = ""
		For Local Offset:Int = 1 To parts.Length - 1
			qry:+ parts[Offset]
			If offset < parts.Length - 1 Then qry :+ "."
		Next
		Return qry
	End Function
	
End Type