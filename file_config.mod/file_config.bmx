' ------------------------------------------------------------------------------
' -- sodaware.file_config
' --
' -- Module for application configuration.
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


Module sodaware.File_Config

ModuleInfo "Version: 0.2.0"
ModuleInfo "Author: Phil Newton"

SuperStrict

Import brl.map
import brl.linkedlist
Import brl.reflection

Import "src/config.bmx"
Import "src/config_serializer.bmx"

Type File_Config
   
	Function Load:Config(fileName:String)
		
		' Check if each serializer can load the file.
		Local baseType:TTypeId = TTypeId.ForName("File_ConfigSerializer")
		For Local serializer:TTypeId = EachIn baseType.DerivedTypes()
			
			' If serializer can load the file, load it
			Local loader:File_ConfigSerializer = File_ConfigSerializer(serializer.NewObject())
			If loader.canLoad(fileName) Then
				Return loader.loadFile(fileName)
			End If
			
		Next
		
	End Function
	
End Type
