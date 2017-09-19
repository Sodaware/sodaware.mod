' ------------------------------------------------------------------------------
' -- src/zip_helper.bmx
' -- 
' -- Simpler wrapper for GMan's ZipEngine library that allows files to be
' -- extracted in a single call.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import gman.zipengine
Import brl.retro

Include "zip_file_stream_factory.bmx"


''' <summary>Holds helper functions for working with Zip files.</summary>
Type ZipHelper
	
	''' <summary>Extracts a file to a stream.</summary>
	''' <param name="zipName">The zip file to open.</param>
	''' <param name="fileName">The file within the zip to extract.</param>
	''' <param name="password">Optional password required to extract.</param>
	''' <param name="ignoreCase">If true, will ignore case when loading.</param>
	''' <returns>A Stream for reading the file contents, or null on error.</returns>
	Function ExtractFile:TStream(zipName:string, fileName:string, password:string = "", ignoreCase:int = true)
		
		' -- Check inputs
		If FileType(zipName) <> FILETYPE_FILE Then Return Null
		
		' -- Open the zip
		local zipIn:ZipReader = new ZipReader
		zipIn.OpenZip(zipName)
		
		' -- Get the file, cleanup & return
		Local stream:TStream = zipIn.ExtractFile(fileName, Not(ignoreCase), password)
		zipIn.Closezip()
		
		Return stream
		
	End Function
	
	Function ExtractFileToDisk:String(zipName:String, fileName:String, outputName:String, password:String = "", ignoreCase:Int = True)
		
		' -- Check inputs
		If FileType(zipName) <> FILETYPE_FILE Then Return Null
		
		' -- Open the zip
		Local zipIn:ZipReader = New ZipReader
		zipIn.OpenZip(zipName)
		
		zipIn.ExtractFileToDisk(fileName, outputName, Not(ignoreCase), password)
		zipIn.Closezip()
		
		Return outputName
		
	End Function
	
	
	' ------------------------------------------------------------
	' -- Protocol Helpers
	' ------------------------------------------------------------
		
	''' <summary>Extract a file from a zip using a full path. Supports passwords.</summary>
	Function ExtractFileFromFullPath:TStream(zipPath:String)
		
		Return ZipHelper.ExtractFile( .. 
			ZipHelper._getZipName(zipPath), ..
			ZipHelper._getFileName(zipPath), ..
			ZipHelper._getPassword(zipPath) .. 
		)
		
	End Function
	
	''' <summary>
	''' Extract a file from a zip using a full path and save it to another
	''' file. Supports passwords.
	''' </summary>
	Function ExtractFileToDiskFromFullPath:String(zipPath:String, outputName:String)

		Return ZipHelper.ExtractFileToDisk( .. 
			ZipHelper._getZipName(zipPath), ..
			ZipHelper._getFileName(zipPath), ..
			outputName, ..	
			ZipHelper._getPassword(zipPath) .. 
		)
		
	End Function
	
	Function GetFileList:TList(zipPath:String)

		Local fileList:TList = New TList

		' Open the archive
		Local fileIn:ZipReader = New ZipReader
		fileIn.OpenZip(zipPath)

		If fileIn.m_zipFileList.getFileCount() = 0 Then Return fileList

		For Local zipFileInfo:SZipFileEntry = EachIn fileIn.m_zipFileList.fileList
			Local fileName:String = zipFileInfo.simpleFileName

			If fileName = "." Or fileName = ".." Then Continue
			fileList.AddLast(fileName)

		Next

		fileIn.CloseZip()

		Return fileList

	End Function


    ' ------------------------------------------------------------
	' -- Zip path extractors
	' ------------------------------------------------------------
	
	Function _getPassword:String(zipPath:String)
	
		' Check if fileName contains an @ - ignore password in that case
		If zipPath.Contains("://") Then 
			If zipPath.Find("@") > zipPath.Find("://") Then Return ""
		EndIf
		
		Return Left(zipPath, zipPath.Find("@"))
	End Function
	
	Function _getZipName:String(zipPath:String)
	
		If zipPath.Contains("://") And zipPath.Find("@") > zipPath.Find("://") Then 
			If zipPath.Find("@") > 1 Then Return Mid(zipPath, 0, zipPath.Find("://") + 1)
		EndIf
	
		If zipPath.Contains("://") Then
			Return Mid(zipPath, zipPath.Find("@") + 2 , zipPath.Find("://") - zipPath.Find("@") - 1)
		EndIf
		
		Return Mid(zipPath, zipPath.Find("@") + 2)
					
	End Function

	Function _getFileName:String(zipPath:String)
		If zipPath.Contains("://") Then
			Return Right(zipPath, zipPath.Length - zipPath.Find("://") - 3)
		Else
			Return ""
		EndIf
	End Function
	
End Type
