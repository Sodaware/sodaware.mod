' ------------------------------------------------------------------------------
' -- sodaware.file_util
' --
' -- Utility class containing helper functions for common file operations.
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

Module sodaware.File_Util

Import brl.basic
Import brl.retro
Import brl.filesystem

Import BaH.volumes
Import sodaware.file_fnmatch

Import "file_information.bmx"

Type File_Util

	Const SEPARATOR:String = "/"

	''' <summary>
	''' Read the entire contents of a stream and return it as a string.
	''' </summary>
	''' <param name="url">The stream or filename to read.</param>
	''' <return>The entire contents as a string.</return>
	Function GetFileContents:String(url:Object)

		' Create a bank and load the file contents.
		Local bank:TBank = LoadBank(url)

		' Ensure bank finishes with a 0 byte.
		' This prevents the string from having junk bytes at the end.
		Local size:Int = BankSize(bank)

		?bmxng
		ResizeBank(bank, size_t(size + 1))
		?Not bmxng
		ResizeBank(bank, size + 1)
		?

		PokeByte(bank, size, 0)

		' Get bank contents and convert to a string
		Local buffer:Byte Ptr = LockBank(bank)
		Local content:String  = String.FromCString(buffer)

		' Cleanup.
		UnlockBank(bank)
		bank = null

		Return content

	End Function

	''' <summary>Write a string as an entire file.</summary>
	''' <param name="url">The stream or filename to write to.</param>
	''' <param name="content">The string contents to write.</param>
	Function PutFileContents(url:Object, content:String)
		Local streamOut:TStream = WriteFile(url)
		streamOut.WriteString(content)
		streamOut.Close()
	End Function


	''' <summary>Get information about a file.</summary>
	''' <param name="fileName">Path to file.</param>
	''' <return>A FileInformation object, or null if not found.</return>
	Function GetInfo:FileInformation(fileName:String)
		Return FileInformation.Create(fileName)
	End Function

	''' <summary>Get the location of the temporary directory.</summary>
	''' <return>The temp path.</return>
	Function GetTempDir:String()

		?Win32
		Local Aux:String = getenv_("TEMP")
		If Aux = "" Then Aux = getenv_("TMP")
		Return Aux
		?Not Win32
		' TODO: Don't assume this is "/tmp/"
		Return "/tmp"
		?

	End Function

	''' <summary>Get the location of the home directory.</summary>
	''' <return>Path of the user's home directory.</return>
	Function GetHomeDir:String()
		Return GetUserHomeDir()
	End Function

	''' <summary>
	''' Generate a path for a settings directory, based on a company and
	''' application name. The directory path will be inside the user's app data
	''' directory.
	'''
	''' For example, on GNU/Linux this will be something like:
	''' `~/.companyName/applicationName/`.
	'''
	''' Does not create the directory.
	''' </summary>
	''' <param name="companyName">The company name.</param>
	''' <param name="applicationName">The application name.</param>
	''' <return>The full path of the settings directory.</return>
	Function GetSettingsDirectory:String(companyName:String, applicationName:String)

		Local companyDir:String
		Local applicationDir:String

		' Hide directories on a linux system
		?Win32
		companyDir		= companyName
		applicationDir	= applicationName
		?Not Win32
		companyDir		= "." + companyName
		applicationDir	= applicationName
		?

		Return File_Util.PathCombine(GetUserAppDir(), File_Util.PathCombine(companyDir, applicationDir))

	End Function

	''' <summary>
	''' Combine two file paths together.
	'''
	''' Automatically collapses "../" characters, removes double slashes and
	''' adds separators.
	''' </summary>
	''' <param name="pathName">The first part to join.</param>
	''' <param name="fileName">The second part to join.</param>
	''' <return>The joined path.</return>
	Function PathCombine:String(pathName:String, fileName:String)

		' Don't combine if no path or filename.
		If pathName = "" Then Return fileName
		If fileName = "" Then Return pathName

		' Create the initial path.
		Local combinedPath:String = pathName:String + fileName:String

		' Collapse any "../" paths.
		If Left(fileName, 3) = "../" Or Left(filename, 3) = "..\" Then
			Repeat
				' Strip trailing slash from path.
				If pathName.endsWith("/") Or pathName.endsWith("\") Then
					pathName = StripSlash(pathName)
				EndIf

				pathName = ExtractDir(pathName)
				fileName = Right(fileName, Len(fileName) - 3)

				If Left(fileName, 3) <> "../" And Left(fileName, 3) <> "..\" Then Exit
			Forever

			combinedPath = pathName + File_Util.SEPARATOR + fileName
		EndIf

		' Trim trailing slashes.
		If Right(pathName, 1) = "/" Or Right(pathName, 1) = "\" Then
			If Left(fileName, 1) = "/" Or Left(fileName, 1) = "\" Then
				combinedPath = pathName + Right(fileName, Len(fileName) - 1)
			EndIf
		Else
			If Left(fileName, 1) <> "/" And Left(fileName, 1) <> "\" Then
				combinedPath = pathName + File_Util.SEPARATOR + fileName
			EndIf
		EndIf

		Return combinedPath

	End Function

	''' <summary>Get a list of all files in a directory and its child directories.</summary>
	''' <param name="dir">The directory to list.</param>
	''' <param name="exclude">Optional array of file patterns to exclude. See file_fnmatch for pattern examples.</param>
	''' <return>String array of full paths for each file.</return>
	Function DirectoryList:String[](dir:String, exclude:String[] = Null)
		Local list:String[]
		Local files:String[] = LoadDir(dir)
		Local canAdd:Byte    = True

		For Local fileName:String = EachIn files
			' Can always add file names by default.
			canAdd = True

			' If filename is a directory, scan it and add its contents to the list.
			If FileType(dir + "/" + fileName) = FILETYPE_DIR Then
				Local ls:String[] = File_Util.DirectoryList(File_Util.PathCombine(dir, fileName), exclude)
				list = list + ls
			Else
				' Test against any patterns.
				If exclude And exclude.length Then
					For Local pattern:String = EachIn exclude
						If fnmatch(fileName, pattern) Then
							canAdd = False
							Exit
						EndIf
					Next
				EndIf

				' Only add the file to the list of all patterns failed.
				If canAdd Then
					list = list[..list.Length + 1]
					list[list.Length - 1] = File_Util.PathCombine(dir, fileName)
				EndIf
			EndIf
		Next

		Return list
	End Function

End Type
