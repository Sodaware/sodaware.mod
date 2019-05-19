' ------------------------------------------------------------------------------
' -- src/ini_file_section.bmx
' --
' -- Type that wraps a section within an ini file. A section has a name and is
' -- made up of key/value pairs.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.linkedlist
Import brl.map

Type IniFileSection
	Field _name:String
	Field _values:TMap


	' ------------------------------------------------------------
	' -- Querying
	' ------------------------------------------------------------

	Method getName:String()
		Return Self._name
	End Method

	Method setValue(keyName:String, value:String)
		Self._values.Insert(keyName, value)
	End Method

	Method getValue:String(keyName:String)
		Return String(Self._values.ValueForKey(keyName))
	End Method

	Method deleteValue(keyName:String)
		Self._values.Remove(keyName)
	End Method

	Method getKeyNames:String[]()
		Local keyNames:String[]

		For Local key:String = EachIn Self._values.Keys()
			keyNames = keyNames[..keyNames.Length + 1]
			keyNames[keyNames.Length - 1] = key
		Next

		Return keyNames
	End Method


	' ------------------------------------------------------------
	' -- String Output
	' ------------------------------------------------------------

	Method toString:String()
		' Write header.
		Local output:String = "[" + Self._name + "]~n"

		' Write each key.
		For Local keyName:String = EachIn Self._values.Keys()
			output :+ keyName + "=" + Self.getValue(keyName) + "~n"
		Next

		' End with an extra blank line.
		Return output + "~n"
	End Method


	' ------------------------------------------------------------
	' -- Creation / Destruction
	' ------------------------------------------------------------

	Function Create:IniFileSection(name:String)
		Local this:IniFileSection = New IniFileSection

		this._name = name

		Return this
	End Function

	Method New()
		Self._values = New TMap
	End Method

End Type
