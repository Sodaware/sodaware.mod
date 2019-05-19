' ------------------------------------------------------------------------------
' -- sodaware.file_config_iniserializer
' --
' -- Load INI based configuration files.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2019 Phil Newton
' --
' -- This library is free software; you can redistribute it and/or modify
' -- it under the terms of the GNU Lesser General Public License as
' -- published by the Free Software Foundation; either version 3 of the
' -- License, or (at your option) any later version.
' --
' -- This library is distributed in the hope that it will be useful,
' -- but WITHOUT ANY WARRANTY; without even the implied warranty of
' -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' -- GNU Lesser General Public License for more details.
' --
' -- You should have received a copy of the GNU Lesser General Public
' -- License along with this library (see the file LICENSE for more
' -- details); If not, see <http://www.gnu.org/licenses/>.
' ------------------------------------------------------------------------------


SuperStrict

Module sodaware.File_Config_IniSerializer

Import brl.filesystem
Import brl.retro

Import sodaware.file_config
Import sodaware.File_INI

''' <summary>
''' Configuration serializer for working with INI files.
''' </summary>
Type IniConfigSerializer Extends File_ConfigSerializer

	' ------------------------------------------------------------
	' -- File Type Checking
	' ------------------------------------------------------------

	''' <summary>Check if serializer can load the file.</summary>
	''' <param name="fileName">The full path of the file to check.</param>
	''' <returns>True if file can be loaded by this serializer, false if not.</returns>
	Method canLoad:Byte(fileName:String)

		' Check extension first.
		If Lower(ExtractExt(fileName)) = "ini" Then Return True

		' File extension told us nothing, so look at the first non-empty line.
		Local firstLine:String = Self.readFirstLine(fileName)

		If firstLine = "" Then Return False

		Return (Instr("#[;", Left(firstLine, 1)) > 0)

	End Method


	' ------------------------------------------------------------
	' -- Loading and Saving
	' ------------------------------------------------------------

	''' <summary>Load a configuration object from an INI file.</summary>
	''' <param name="cfg">The config object to load data into.</param>
	''' <param name="fileName">The name of the file to load from.</param>
	''' <returns>True on success, false on failure.</returns>
	Function Load:Byte(cfg:Config, fileName:String)

		' Check the file can be loaded.
		If FileType(filename) <> FILETYPE_FILE Then Return False

		' Read the ini file.
		Local configDoc:IniFile = File_INI.LoadFile(fileName)
		If configDoc = Null Then Return False

		' Load sections.
		For Local section:IniFileSection = EachIn configDoc.getSections()
			Local sectionName:String = section.getName()
			' Load each key.
			For Local keyName:String = EachIn section.getKeyNames()
				cfg.SetKey(sectionName, keyName, section.getValue(keyName))
			Next
		Next

		Return True

	End Function

	''' <summary>Save a configuration object to an INI file.</summary>
	''' <param name="cfg">The Config object to save.</param>
	''' <param name="fileName">The name of the file to save to.</param>
	Function Save(cfg:Config, fileName:String)

		' Create new INI document.
		Local fileOut:IniFile = New IniFile

		' Add each section.
		Local sections:TList = cfg.getSections()
		For Local sectionName:String = EachIn sections
			' Add the section.
			fileOut.addSection(sectionName)

			' Add each key.
			Local sectionKeys:TList = cfg.getSectionKeys(sectionName)
			For Local keyName:String = EachIn sectionKeys
				fileOut.set(sectionName, keyName, cfg.getKey(sectionName, keyName))
			Next
		Next

		' Save the file.
		File_Ini.Save(fileName, fileOut)

	End Function

End Type
