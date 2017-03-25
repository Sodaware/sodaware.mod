' ------------------------------------------------------------
' -- src/soda_file_exceptions.bmx
' -- 
' -- Exceptions that can be thrown by the `file_soda` module.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Type SodaFileException Extends TBlitzException
End Type

Type SodaFileUnterminatedLineException Extends SodaFileException

	Field _message:String

	Method ToString:String()
		Return "Attempted to close a group without terminating the previous line: `" + Self._message + "`"
	End Method
	
	Function Create:SodaFileUnterminatedLineException(message:String)
		Local this:SodaFileUnterminatedLineException = New SodaFileUnterminatedLineException
		this._message = message
		Return this
	End Function
	
End Type
