' ------------------------------------------------------------------------------
' -- src/logger/debug_timer.bmx
' --
' -- Stores timing information inside a debug log.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2025 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

''' <summary>
''' Timer object used by DebugLogger to track execution time of code blocks.
'''
''' This object also tracks the total number of times a timer was called, as well
''' as the total execution time in milliseconds.
''' </summary>
Type DebugTimer
	Field Name:String
	Field Calls:Int
	Field TotalTime:Int
	Field _timerBuffer:Int	' Temp variable to hold start time in millisecs

	''' <summary>Create a new named timer.</summary>
	''' <param name="name">The name for this timer.</param>
	''' <return>A new DebugTimer instance.</return>
	Function Create:DebugTimer(name:String)
		Local this:DebugTimer = New DebugTimer

		this.Name = Name

		Return this
	End Function

	''' <summary>Start the timer.</summary>
	''' <remarks>If timer is already running, it will be stopped first.</remarks>
	Method start()
		' Stop the timer if it's already running
		If Self._timerBuffer > 0 Then Self.stop()

		Self._timerBuffer = MilliSecs()
	End Method

	''' <summary>Stop the timer and add elapsed time to total.</summary>
	Method stop()
		Self.Calls:+ 1

		If Self._timerBuffer = 0 Then Return

		Self.TotalTime = Self.TotalTime + (MilliSecs() - Self._timerBuffer)
		Self._timerBuffer = 0
	End Method

End Type
