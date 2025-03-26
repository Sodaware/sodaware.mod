' ------------------------------------------------------------------------------
' -- src/process_id.bmx
' --
' -- Functions for getting the id of the current process.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Extern "OS"
	?Win32
		Function GetCurrentProcessId:Int() = "GetCurrentProcessId@0"
	?MacOS
		Function GetCurrentProcessId:Int() = "getpid"
	?Linux
		Function GetCurrentProcessId:Int() = "getpid"
	?
End Extern

''' <summary>
''' Get the current process id.
'''
''' Alias for `GetCurrentProcessId`.
''' </summary>
''' <return>The current process id.</summary>
Function GetPid:Int()
	Return GetCurrentProcessId()
End Function
