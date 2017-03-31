' ------------------------------------------------------------------------------
' -- src/zip_file_stream_factory.bmx
' -- 
' -- BlitzMax stream factory for working with zip files.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Type ZipFileStreamFactory extends TStreamFactory
	
	Method CreateStream:TStream(url:Object, proto:String, path:String, readable:Int, writeable:Int)
		
		' Check inputs
		If proto <> "zip" Then Return Null
		If writeable And Not readable Then Throw "The zip:: protocol does not support writing"
		
		' Return the extracted file stream
		Return ZipHelper.ExtractFileFromFullPath(path)
		
	End Method
	
End Type

' Register factory with BlitzMax
New ZipFileStreamFactory
