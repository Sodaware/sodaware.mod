' ------------------------------------------------------------------------------
' -- sodaware.file_config_sodaserializer
' --
' -- Load SODA based configuration files.
' -- 
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2017 Phil Newton
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


Module sodaware.File_Config_SodaSerializer

ModuleInfo "Version: 0.1.0"
ModuleInfo "Author: Phil Newton"

SuperStrict

Import sodaware.file_config
Import sodaware.file_soda


Type SodaConfigSerializer Extends File_ConfigSerializer
	
	' ------------------------------------------------------------
	' -- File Type Checking
	' ------------------------------------------------------------
	
	''' <summary>Check if serializer can load the file.</summary>
	Method canLoad:Byte(fileName:String)
		Return "soda" = Lower(ExtractExt(fileName))
	End Method
	
	
	' ------------------------------------------------------------
	' -- Loading & Saving
	' ------------------------------------------------------------
	
	''' <summary>Loads a configuration object from a SODA file.</summary>
	''' <param name="cfg">The Config object to load data into.</param>
	''' <param name="fileName">The name of the file to load from.</param>
	''' <returns>True on success, false on failure.</returns>
	Function Load:Byte(cfg:Config, fileName:String)
		
		' Read Document
		Local configDoc:SodaFile = sodafile.Load(filename)
		If configDoc = Null Then Return False
		
		' Load sections
		For Local section:SodaGroup = EachIn configDoc.getGroups()
			Local sectionName:String = section.getIdentifier()
			For Local keyName:String = EachIn section.getFieldNames()
				cfg.setKey(sectionName, keyName, section.getFieldString(keyName))
			Next	
		Next
		
		Return True
		
	End Function
	
	' TODO: No way to save Soda files (yet)
	Function Save(cfg:Config, fileName:String)
		
	End Function
	
End Type
