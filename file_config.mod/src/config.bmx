' ------------------------------------------------------------------------------
' -- src/config.bmx
' -- 
' -- A basic configuration object for use with BlitzMax. All loading and saving
' -- is done via config serializers.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.map
Import brl.linkedlist


''' <summary>
''' Object to handle an internal configuration that can be saved
''' and loaded from various formats.
''' </summary>
Type Config
	
	Field _sections:TMap                   '''< Internal Map to store sections.
	
	
	' ------------------------------------------------------------
	' -- Getting / Setting Keys
	' ------------------------------------------------------------
	
	''' <summary>Gets a key from the configuration file. Will Return the Default value If Not found.</summary>
	''' <param name="sectionName">The section to find the key in.</param>
	''' <param name="keyName">The name of the key to get.</param>
	''' <param name="defaultValue">Optional default value to return if no key found.</param>
	''' <returns>The value of the key found, or the default value if not found.</returns>
	Method getKey:String(sectionName:String, keyName:String, defaultValue:String = "")
				
		Local returnValue:String = defaultValue
		
		' Search all sections for a list of keys
		Local configSection:TMap = TMap(Self._sections.ValueForKey(sectionName))
		
		' If index != null (ie found a valid handle), then search this string hash for values
		If configSection <> Null Then
			If (configSection.ValueForKey(keyName)) <> Null Then
				returnValue = String(configSection.ValueForKey(keyName))
			EndIf
		EndIf
		
		Return returnValue
		
	End Method
		
	''' <summary>
	''' Set a key within the configuration. Will add the key if
	''' not present, or overwrite an existing value If it is set.
	''' </summary>
	''' <param name="sectionName">The section to add the key to.</param>
	''' <param name="keyName">The name of the key to set.</param>
	''' <param name="keyValue">The value of the new key.</param>
	''' <returns>True if key added, false if not.</returns>
	Method setKey:Int(sectionName:String, keyName:String, keyValue:String)
		
		' Check if the section already exists
		Local configSection:TMap = TMap(Self._sections.ValueForKey(sectionName))
		
		' If no map of keys, create a new one & set index
		If configSection = Null Then
			configSection = New TMap
			Self._sections.Insert(sectionName, configSection)
		EndIf
		
		' Add key to section
		configSection.Insert(keyName, keyValue)
		
		Return True
		
	End Method
	
	
	' ------------------------------------------------------------
	' -- Querying the Config
	' ------------------------------------------------------------
	
	''' <summary>Returns a list of section names.</summary> 
	Method getSections:TList()
		
		' TODO: Convert this to a StringList
		Local sections:TList = New TList
		
		For Local sectionName:String = EachIn Self._sections.Keys()
			sections.AddLast(sectionName)
		Next
		
		Return sections
		
	End Method
	
	''' <summary>Get a list of all keys in a section.</summary>
	Method getSectionKeys:TList(sectionName:String)
		
		' Check section exists
		If Not Self.hasSection(sectionName) Then Return Null
	
		Local section:TMap      = TMap(Self._sections.ValueForKey(sectionName))
		Local sectionKeys:TList = New TList
		
		For Local sectionName:String = EachIn section.Keys()
			sectionKeys.AddLast(sectionName)
		Next
		
		' TODO: Convert this to a StringList
		Return sectionKeys
		
	End Method

	Method hasSection:Byte(sectionName:String)
		Return Self._sections.ValueForKey(sectionName) <> Null
	End Method
	
	
	' ------------------------------------------------------------
	' -- Object Creation & Destruction
	' ------------------------------------------------------------
	
	''' <summary>Create And initialise a New, empty configuration.</summary>
	''' <returns>The newly created configuration object.</returns>
	Method New()
		Self._sections = New TMap
	End Method

End Type
