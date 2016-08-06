' ------------------------------------------------------------------------------
' -- sodaware.stringtable
' -- 
' -- Works in a similar way to a TMap, but is strongly typed for strings.
' ------------------------------------------------------------------------------


SuperStrict

Module sodaware.stringtable

Import brl.map

''' <summary>
''' Get and set string values. Works in a similar way to a TMap, 
''' but is strongly typed for strings.
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

