' ------------------------------------------------------------------------------
' -- src/serializers/abstract_debug_log_serializer.bmx
' --
' -- Base type that all DebugLogger serializers must extend.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2025 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Type AbstractDebugLogSerializer

	''' <summary>Base type for serializing DebugLogger output to different formats.</summary>
	''' <param name="log">The DebugLogger instance to save.</param>
	''' <param name="fileName">The name of the file to save to.</param>
	Method saveToFile(log:DebugLogger, fileName:String) Abstract

	' ------------------------------------------------------------
	' -- Utility Functions
	' ------------------------------------------------------------

	''' <summary>Get a human-readable version of a DEBUG_LEVEL constant.</summary>
	''' <param name="debugLevel">The DEBUG_LEVEL constant to look up.</param>
	''' <return>A human-readable string, or NULL if an invalid constant was passed.</return>
	Function GetLevelText:String(debugLevel:Int)

		Select debugLevel
			' Grouped Levels.
			Case DEBUG_LEVEL_ALL;		Return "DEBUG_LEVEL_ALL (All messages)"
			Case DEBUG_LEVEL_DEFAULT;	Return "DEBUG_LEVEL_DEFAULT (All messages except detailed)"
			Case DEBUG_LEVEL_LITE;		Return "DEBUG_LEVEL_LITE (Urgent and general messages only)"

			' Single levels.
			Case DEBUG_LEVEL_URGENT;	Return "DEBUG_LEVEL_URGENT (Urgent messages only)"
			Case DEBUG_LEVEL_GENERAL;	Return "DEBUG_LEVEL_GENERAL (General messages only)"
			Case DEBUG_LEVEL_LOW;		Return "DEBUG_LEVEL_LOW (Low priority messages only)"
			Case DEBUG_LEVEL_DETAILED;	Return "DEBUG_LEVEL_DETAILED (Detailed messages only)"
		End Select

	End Function

	' ------------------------------------------------------------
	' -- Internal Helpers
	' ------------------------------------------------------------

	''' <summary>Get the current build mode (release or debug).</summary>
	''' <return>Build mode string. Either "Debug" or "Release".</return>
	Method _getBuildMode:String()
		?Debug		Return "Debug"
		?Not Debug	Return "Release"
		?
	End Method

	''' <summary>Get the human-readable debug level for a log.</summary>
	''' <param name="log">The DebugLogger to query.</param>
	''' <return>Debug level name.</return>
	Method _getDebugLoggerLevel:String(log:DebugLogger)
		Return GetLevelText(log._debugLevel)
	End Method

End Type
