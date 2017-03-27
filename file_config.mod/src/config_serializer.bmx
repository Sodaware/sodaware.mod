' ------------------------------------------------------------------------------
' -- src/config_serializer.bmx
' -- 
' -- A basic configuration serializer. Extend this to add support for different
' -- file formats.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.stream
Import brl.filesystem

Import "config.bmx"

Type File_ConfigSerializer
	
	Method canLoad:Byte(fileName:String) Abstract
	
	Method loadFile:Config(fileName:String)
		
		' [todo] - Open the file here?
		
		Local this:Config = New Config
		Self.Load(this, fileName)
		Return this
	End Method
	
	Method saveFile:Config(this:Config, fileName:String)
		Self.Save(this, fileName)
	End Method

	Function Load:Int(this:Config, fileName:String) Abstract
	Function Save(this:Config, fileName:String) Abstract
	
	
	' ------------------------------------------------------------
	' -- Utility functions
	' ------------------------------------------------------------
	
	''' <summary>
	''' Get the first non-empty line from a file. Use to check file header.
	''' </summary>
	Method readFirstLine:String(fileName:String)
		
		Local fileIn:TStream     = ReadFile(fileName)
		If fileIn = Null Then Return ""
		
		
		Local currentLine:String = filein.ReadLine().Trim()
		
		While currentLine = "" And fileIn.Eof() = False
			currentLine = fileIn.ReadLine().Trim()
		Wend
		
		fileIn.Close()
		
		Return currentLine
		
	End Method
	
End Type
