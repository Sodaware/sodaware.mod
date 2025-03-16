' ------------------------------------------------------------------------------
' -- src/logger/debug_logger.bmx
' --
' -- Main type used for debug logging.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2025 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import BRL.Map
Import brl.hook

Import "debug_log_constants.bmx"
Import "debug_log_entry.bmx"
Import "debug_timer.bmx"

Include "../serializers/abstract_debug_log_serializer.bmx"

''' <summary>
''' General-purpose debug logger.
'''
''' Supports writing debug messages with different levels of importance, as well
''' as creating timers for measuring code execution time.
'''
''' Can be written to disk using a serializer class.
''' </summary>
Type DebugLogger

	' -- Internal Fields.
	Field _entries:DebugLogEntry[] ''' List of DebugLogEntry objects.
	Field _timers:TMap             ''' Map of name => DebugTimer objects.
	Field _hookID:Int              ''' HookID called when entry is made.
	Field _fields:TMap             ''' Map of fieldName => value.

	' -- Option fields.
	Field _debugLevel:Int          ''' The debug level for this log (not really needed?)
	Field _enableHooks:Byte        ''' Will hooks be called on write?
	Field _enableBmxLog:Byte       ''' Will DebugLog be called on write?


	' ------------------------------------------------------------
	' -- Logging options
	' ------------------------------------------------------------

	''' <summary>Enable or disable hooks.</summary>
	Method enableHooks:DebugLogger(e:Byte = True)
		Self._enableHooks = e

		Return Self
	End Method

	''' <summary>Enable or disable writing messages to blitzmax debuglog.</summary>
	Method enableBlitzMaxDebugLog:DebugLogger(e:Byte = True)
		Self._enableBmxLog = e

		Return Self
	End Method

	''' <summary>Get the ID of the hook used when Write is called.</summary>
	Method getHookID:Int()
		Return Self._hookID
	End Method


	' ------------------------------------------------------------
	' -- Logging Messages
	' ------------------------------------------------------------

	''' <summary>Write a message to the debug log.</summary>
	''' <param name="messageText">The message to write.</param>
	''' <param name="messageLevel">Optional level for this message. Defaults to load.</param>
	''' <return>Logger instance</return>
	Method write:DebugLogger(messageText:String, messageLevel:Int = DEBUG_LEVEL_LOW)
		' Write to BlitxMax debug log and run hooks if enabled.
		If Self._enableBmxLog Then DebugLog(messageText)
		If Self._enableHooks Then RunHooks(Self._hookID, messageText)

		' Create and add new debuglog entry.
		Local entry:DebugLogEntry = DebugLogEntry.Create(messagetext, messagelevel)
		Self._entries = Self._entries[..Self._entries.Length + 1]
		Self._entries[Self._entries.Length - 1] = entry

		Return Self
	End Method


	' ------------------------------------------------------------
	' -- Timing
	' ------------------------------------------------------------

	''' <summary>Starts a debug timer.</summary>
	''' <param name="timerName">The name of the timer to start. Case sensitive.</param>
	Method startTimer(timerName:String)

		Local timer:DebugTimer = DebugTimer(Self._timers.ValueForKey(timerName))
		If timer = Null Then
			timer = DebugTimer.Create(timerName)
			Self._timers.Insert(timerName, timer)
		End If

		timer.start()

	End Method

	''' <summary>Stops a debug timer.</summary>
	''' <param name="timerName">The name of the timer to stop. Case sensitive.</param>
	Method stopTimer(timerName:String)

		Local timer:DebugTimer = DebugTimer(Self._timers.ValueForKey(timerName))

		If timer = Null Then	' Error - can't find timer to stop
			Throw "Timer " + timerName + " not found"
		EndIf

		timer.Stop()

	End Method


	' ------------------------------------------------------------
	' -- Watching Variables
	' ------------------------------------------------------------

	''' <summary>Add a variable to the debug log.</summary>
	''' <remarks>Use for storing app info, such as version number, name etc.</remarks>
	''' <param name="varName">The name of the variable to store.</param>
	''' <param name="varValue">The value of this variable.</param>
	Method setField(varName:String, varValue:Object)
		Self._fields.Insert(varName, varValue)
	End Method


	' ------------------------------------------------------------
	' -- Saving functions
	' ------------------------------------------------------------

	Method save(fileName:String, serializer:AbstractDebugLogSerializer)
		serializer.saveToFile(Self, fileName)
	End Method


	' ------------------------------------------------------------
	' -- Object Construction
	' ------------------------------------------------------------

	Method New()
		Self._entries      = New DebugLogEntry[0]
		Self._timers       = New TMap
		Self._fields       = New TMap
		Self._hookID       = AllocHookId()

		' Default options
		Self._debugLevel   = DEBUG_LEVEL_ALL
		Self._enableHooks  = True
		Self._enableBmxLog = True
	End Method

	''' <summary>Create a new debuglog with a set debug level.</summary>
	''' <param name="debugLevel">Optional debug level
	Function Create:DebugLogger(debugLevel:Int = DEBUG_LEVEL_ALL)
		Local this:DebugLogger = New DebugLogger

		this._debugLevel = debugLevel

		Return this
	End Function

End Type
