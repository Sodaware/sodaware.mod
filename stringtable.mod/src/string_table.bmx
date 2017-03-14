' ------------------------------------------------------------------------------
' -- src/string_table.bmx
' --
' -- StringTable object definition.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.map

''' <summary>
''' Get and set string values. Works in a similar way to a TMap, 
''' but is strongly typed for strings.
'''
''' Use `get` and `set` methods for fetching and setting data.
''' </summary>
Type StringTable
	
	Field _strings:TMap
	
	
	' ------------------------------------------------------------
	' -- Getting and Setting
	' ------------------------------------------------------------
	
	''' <summary>Get the value for key in the string table.</summary>
	''' <param name="key">The key to search for.</param>
	''' <return>The value found, or an empty string if not found.</return>
	Method get:String(key:String)
		Return String(Self._strings.ValueForKey(key))
	End Method
	
	''' <summary>Set the value for key in the string table.</summary>
	''' <param name="key">The key to set.</param>
	''' <param name="value">The value to set.</param>
	''' <return>The stringtable object.</return>
	Method set:StringTable(key:String, name:String)
		Self._strings.Insert(key, name)
		Return Self
	End Method

	
	' ------------------------------------------------------------
	' -- Creation / Destruction
	' ------------------------------------------------------------
	
	Method New()
		Self._strings = New TMap
	End Method
	
End Type
