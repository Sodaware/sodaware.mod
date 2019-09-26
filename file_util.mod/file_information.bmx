' ------------------------------------------------------------------------------
' -- file_information.bmx
' --
' -- Basic information about a file.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.filesystem

Type FileInformation
	Field name:String
	Field longtime:Int

	Field hour:Byte
	Field minute:Byte
	Field second:Byte
	Field day:Byte
	Field month:Byte
	Field year:Int


	' ----------------------------------------------------------------------
	' -- Fetching Info
	' ----------------------------------------------------------------------

	''' <summary>Get the time as a formatted hour:minute:second</summary>
	Method getFormattedTime:String()
		' TODO: Allow a format to be passed in.
		Return Self.hour + ":" + Self.minute + ":" + Self.second
	End Method

	''' <summary>Get the date as a formatted year-month-day.</summary>
	Method getFormattedDate:String()
		' TODO: Allow a format to be passed in.
		Return Self.year + "-" + Self.month + "-" + Self.day
	End Method

	''' <summary>Get the date and time.</summary>
	Method toString:String()
		Return Self.getFormattedDate() + " " + Self.getFormattedTime()
	End Method


	' ----------------------------------------------------------------------
	' -- Querying Files
	' ----------------------------------------------------------------------

	''' <summary>
	''' Get information about a file and store it in the object.
	''' </summary>
	''' <param name="file">The name of the file to query.</param>
	''' <return>Self</return>
	Method getFileInformation:FileInformation(file:String)
		Local fTime:Int    = FileTime(file)
		Local time:Int Ptr = Int Ptr(localtime_(Varptr(fTime)))

		' Set file name and file time.
		Self.name     = file
		Self.longtime = fTime

		' Set month and time parts.
		Self.hour   = time[2]
		Self.minute = time[1]
		Self.second = time[0]
		Self.day    = time[3]
		Self.month  = time[4] + 1
		Self.year   = time[5] + 1900
	End Method


	' ----------------------------------------------------------------------
	' -- Sort Helpers
	' ----------------------------------------------------------------------

	Method compare:Int(s:Object)
		Local file:FileInformation = FileInformation(s)

		If file And file.longtime > Self.longtime Then
			Return 1
		ElseIf file And file.longtime < Self.longtime Then
			Return -1
		EndIf

		Return 0
	End Method


	' ----------------------------------------------------------------------
	' -- Construction
	' ----------------------------------------------------------------------

	''' <summary>Create and return a file information object for a file name.</summary>
	''' <param name="fileName">The file to query.</param>
	''' <return>FileInformation object containing information about fileName.</return>
	Function Create:FileInformation(fileName:String)
		Local this:FileInformation	= New FileInformation

		this.getFileInformation(fileName)

		Return this
	End Function
End Type