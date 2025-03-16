' ------------------------------------------------------------------------------
' -- src/serializers/xml_debug_log_serializer.bmx
' --
' -- Save a debug log as XML.
' --
' -- Does not require any external XML libraries.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2025 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import "../logger/debug_logger.bmx"

''' <summary>Save a DebugLogger to disk formatted as XML.</summary>
Type XmlDebugLogSerializer Extends AbstractDebugLogSerializer
	Field _stylesheet:String

	' ----------------------------------------------------------------------
	' -- Creation
	' ----------------------------------------------------------------------

	''' <summary>Create and configure a new serializer.</summary>
	''' <param name="stylesheet">Optional XSL stylesheet url to use.</param>
	Function Create:XmlDebugLogSerializer(stylesheet:String = "")
		Local this:XmlDebugLogSerializer = new XmlDebugLogSerializer

		this._stylesheet = stylesheet

		Return this
	End Function


	' ----------------------------------------------------------------------
	' -- Saving the log
	' ----------------------------------------------------------------------

	Method saveToFile(logInstance:DebugLogger, fileName:String)
		' Create output stream.
		Local fileOut:TStream = WriteFile(fileName)

		' Write XML header.
		fileOut.WriteLine("<?xml version=~q1.0~q?>")

		' Add a stylesheet (if set).
		If self._styleSheet <> "" Then
			fileOut.WriteLine("<?xml-stylesheet type=~qtext/xsl~q href=~q" + Self._stylesheet + "~q ?>")
		EndIf

		' Open the log node.
		fileOut.WriteLine("<DebugLog>")

		' -- Write Header.
		fileOut.WriteLine("~t<Header>")
		fileOut.WriteLine("~t~t<OutputLevel>" + Self._getDebugLoggerLevel(logInstance) + "</OutputLevel>")
		fileOut.WriteLine("~t~t<Date>" + CurrentDate() + "</Date>")
		fileOut.WriteLine("~t~t<Time>" + CurrentTime() + "</Time>")

		' Write configuration info.
		fileOut.WriteLine("~t~t<Configuration>")
		fileOut.WriteLine("~t<App>")
		fileOut.WriteLine("~t~t<BuildMode>" + Self._getBuildMode() + "</BuildMode>")

		For Local key:String = EachIn logInstance._fields.keys()
			Local obj:Object = logInstance._fields.ValueForKey(key)
			fileOut.WriteLine("~t~t<Fields>")
			fileOut.WriteLine("~t~t~t<Name>" + key + "</Name>")
			fileOut.WriteLine("~t~t~t<Value>" + obj.ToString() + "</Value>")
			fileOut.WriteLine("~t~t</Fields>")
		Next

		fileOut.WriteLine("~t</App>")

		fileOut.WriteLine("~t<Environment>")
		fileOut.WriteLine("~t</Environment>")

		fileOut.WriteLine("~t<Memory>")
		fileOut.WriteLine("~t~t<TotalPhysical>" + GCMemAlloced() + "</TotalPhysical>")
		fileOut.WriteLine("~t</Memory>")


		fileOut.WriteLine("~t~t</Configuration>")
		fileOut.WriteLine("</Header>")

		' -- Write timers.
		fileOut.WriteLine("<Timers>")

		For Local timer:DebugTimer = EachIn logInstance._timers.Values()
			fileOut.WriteLine("~t<Timer>")
			fileOut.WriteLine("~t~t<Name>" + timer.Name + "</Name>")
			fileOut.WriteLine("~t~t<Calls>" + timer.Calls + "</Calls>")
			fileOut.WriteLine("~t~t<Time>" + timer.TotalTime + "</Time>")
			fileOut.WriteLine("~t</Timer>")
		Next

		fileOut.WriteLine("</Timers>")

		' -- Write entries

		fileOut.WriteLine("<Entries>")

		For Local entry:DebugLogEntry = EachIn logInstance._entries
			fileOut.WriteLine("~t<Entry level=~q" + entry.Level + "~q>")
			fileOut.WriteLine("~t~t<Time>" + entry.Time + "</Time>")
			fileOut.WriteLine("~t~t<Message>" + entry.Message + "</Message>")
			fileOut.WriteLine("~t</Entry>")
		Next

		fileOut.WriteLine("</Entries>")

		' Footer
		fileOut.WriteLine("</DebugLog>")

		fileOut.Close()

	End Method
End Type
