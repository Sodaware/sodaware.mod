' ------------------------------------------------------------------------------
' -- src/logger/debug_log_entry.bmx
' --
' -- Stores a single debug message, along with time and severity level.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2025 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import BRL.System

''' <summary>Single message entry in the DebugLogger.</summary>
Type DebugLogEntry

	Field Message:String
	Field Date:String
	Field Time:String
	Field Level:Int

	Function Create:DebugLogEntry(message:String, level:Int, callstack:Object = Null)
		Local this:DebugLogEntry = New DebugLogEntry

		this.Message	= message
		this.Level		= level
		this.Date		= CurrentDate()
		this.Time		= CurrentTime()

		Return this
	End Function

End Type
