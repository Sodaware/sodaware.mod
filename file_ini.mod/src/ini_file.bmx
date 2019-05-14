' ------------------------------------------------------------
' -- src/ini_file.bmx
' --
' -- Type that represents a single INI file.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import "ini_file_section.bmx"

Type IniFile

	Field _sections:IniFileSection[]


	' ------------------------------------------------------------
	' -- Querying
	' ------------------------------------------------------------

	''' <summary>Get the value of a key within a section.</summary>
	''' <param name="sectionName">The section the key belongs to.</param>
	''' <param name="keyName">The key value to retrieve.</param>
	''' <return>The key value. Empty if not found.</return>
	Method get:String(sectionName:String, keyName:String)
		Return Self.getSectionValue(sectionName, keyName)
	End Method

	''' <summary>Set the value of a key within a section.</summary>
	''' <param name="sectionName">The section the key belongs to.</param>
	''' <param name="keyName">The key to set.</param>
	''' <param name="value">The value to set.</param>
	''' <return>Self.</return>
	Method set:IniFile(sectionName:String, keyName:String, value:String)
		Self.setSectionValue(sectionName, keyName, value)

		Return Self
	End Method

	''' <summary>Remove a key from a section. If key name is empty, will remove the entire section.</summary>
	''' <param name="sectionName">The section they key belongs to.</param>
	''' <param name="keyName">Optional key to remove.</param>
	''' <return>Self.</return>
	Method remove:IniFile(sectionName:String, keyName:String = "")
		If keyName = "" Then
			Self.removeSection(sectionName)
		Else
			Self.deleteSectionValue(sectionName, keyName)
		EndIf

		Return Self
	End Method

	''' <summary>Count the number of sections in the file.</summary>
	''' <return>Number of sections.</return>
	Method countSections:Int()
		Return Self._sections.Length
	End Method

	''' <summary>Get all sections for the file.</summary>
	''' <return>Array of section objects in this file.</return>
	Method getSections:IniFileSection[]()
		Return Self._sections
	End Method

	''' <summary>Check if a section exists.</summary>
	''' <param name="sectionName">The section to check for.</param>
	''' <return>True if the section exists, false if not.</return>
	Method hasSection:Byte(sectionName:String)
		Return Self.getSection(sectionName) <> Null
	End Method


	' ------------------------------------------------------------
	' -- Managing Sections
	' ------------------------------------------------------------

	''' <summary>Add a section to the ini file. If section already exists it is returned.</summary>
	''' <param name="sectionName">The name of the section to add.</param>
	''' <return>The added section.</return>
	Method addSection:IniFileSection(sectionName:String)
		' Don't add the section if it already exists
		If Self.getSection(sectionName) Then Return Self.getSection(sectionName)

		' Create the new section.
		Local section:IniFileSection = IniFileSection.Create(sectionName)

		' Resize the section list and add new section to the end.
		Self._sections = Self._sections[.. Self._sections.Length + 1]
		Self._sections[Self._sections.Length - 1] = section

		' Return newly added section.
		Return section
	End Method

	Method getSection:IniFileSection(sectionName:String)
		For Local section:IniFileSection = EachIn Self._sections
			If section._name = sectionName Then Return section
		Next

		Return Null
	End Method

	Method setSectionValue(sectionName:String, key:String, value:String)
		Local section:IniFileSection = Self.getSection(sectionName)

		If section Then section.setValue(key, value)
	End Method

	Method deleteSectionValue(sectionName:String, key:String)
		Local section:IniFileSection = Self.getSection(sectionName)

		If section Then section.deleteValue(key)
	End Method

	Method getSectionValue:String(sectionName:String, key:String)
		Local section:IniFileSection = Self.getSection(sectionName)

		If section Then Return section.getValue(key)
	End Method

	Method removeSection:Byte(sectionName:String)
		Local currentLength:Int = Self.countSections()

		For Local i:Int = 0 To currentLength - 1
			If Self._sections[i].getName() = sectionName Then
				If i < currentLength - 1 Then
					For Local x:Int = i To currentLength - 2
						Self._sections[x] = Self._sections[x + 1]
					Next
				EndIf
				Self._sections = Self._sections[..currentLength - 1]

				Return True

			EndIf
		Next

		Return False
	End Method


	' ------------------------------------------------------------
	' -- String Output
	' ------------------------------------------------------------

	Method toString:String()
		Local output:String
		For Local section:IniFileSection = EachIn Self._sections
			output :+ section.toString()
		Next

		Return output
	End Method

End Type
