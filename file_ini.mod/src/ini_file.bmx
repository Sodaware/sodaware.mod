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

	Method get:String(sectionName:String, keyName:String)
		Return Self.getSectionValue(sectionName, keyName)
	End Method

	Method set:IniFile(sectionName:String, keyName:String, value:String)
		Self.setSectionValue(sectionName, keyName, value)
		Return Self
	End Method

	Method countSections:Int()
		Return Self._sections.Length
	End Method

	Method getSections:IniFileSection[]()
		Return Self._sections
	End Method

	Method hasSection:Byte(sectionName:String)
		Return Self.getSection(sectionName) <> Null
	End Method

	' ------------------------------------------------------------
	' -- Managing Sections
	' ------------------------------------------------------------

	Method addSection:IniFileSection(sectionName:String)

		' Don't add the section if it already exists
		If Self.getSection(sectionName) Then Return Self.getSection(sectionName)

		Local sectionCount:Int = Self.countSections()

		Self._sections = Self._sections[..sectionCount + 1]
		Self._sections[sectionCount] = IniFileSection.Create(sectionName)

		Return Self._sections[sectionCount]

	End Method

	Method getSection:IniFileSection(sectionName:String)
		For Local section:IniFileSection = EachIn Self._sections
			If section.getName() = sectionName Then Return section
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


	' ------------------------------------------------------------
	' -- Creation + Destruction
	' ------------------------------------------------------------

	Method New()

	End Method

End Type
