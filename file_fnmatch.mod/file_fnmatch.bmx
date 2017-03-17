' ------------------------------------------------------------------------------
' -- sodaware.file_fnmatch
' --
' -- Matches a string, usually a file name, against a pattern containing 
' -- tokens. 
' --
' -- Characters:
' -- 	*	-- Matches multiple characters
' --	?	-- Matches a single character
' --	\	-- Escapes a character (use before * or ?)
' --
' -- Example:
' -- 	"*.bmx"			-- True for BlitzMax source files	
' --	"images/*.png"	-- True for all png files in Image folder
' --
' -- Inspired by code from here:
' -- 	* http://www.vcforge.net/1040/nfsLibrary/nfs_pmatch.cpp.html
' --	* http://docs.python.org/library/fnmatch.html
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


SuperStrict

Module sodaware.file_fnmatch

Import brl.retro

' TODO: Allow inverse pattern searches
' TODO: Allow searching using sequence syntax

' - Flag constants
Const FNM_FILE_NAME:Int  = 1
Const FNM_PERIOD:Int     = 2
Const FNM_NO_ESCAPE:Int  = 4


''' <summary>Test whether a string filename matches a pattern.</summary>
''' <param name="fileName">The filename to check.</param>
''' <param name="pattern">The pattern to match against.</param>
''' <param name="flags">Optional flags to use when matching.</param>
''' <returns>True if the file matched the pattern, false if not.</returns>
Function fnmatch:Int(fileName:String, pattern:String, flags:Int = 0)
	Return match(pattern, 0, fileName, 1, flags)
End Function


Private

' Internal matching function
Function match:Int(pattern:String, patternPos:Int, fileName:String, stringPos:Int, flags:Int = 0)

	' Check inputs
	If fileName = "" And pattern = "" Then Return True
	If fileName = "" Then Return False
	If pattern  = "" Then Return False
	
	' Begin
	Local stringChar:String	= Mid(fileName, stringPos, 1)
	Local patternChar:String
	
	Repeat
		
		patternPos	= patternPos + 1
		patternChar	= Mid(pattern, patternPos, 1)
		
		Select patternChar
			
			Case "?"	' Match a single character
				If stringPos >= Len(fileName) Then Return False
				If flags And FNM_FILE_NAME And stringChar = "/" Then Return False
				If flags And FNM_PERIOD And stringChar = "." Then 
					If Mid(fileName, stringPos - 1, 1) = "/" Then Return False
				EndIf
			
			Case "\"	' Escape character
				If Not(flags And FNM_NO_ESCAPE) Then 
					patternPos = patternPos + 1
					patternChar$ = Mid(pattern, patternPos, 1)
				EndIf
				
				If patternChar <> stringChar Then Return False
			
			Case "*"	' Match multiple characters
				
				' Matched
				If patternPos = Len(pattern) Then Return True
				
				' Collapse multiple stars
				While (patternPos < pattern.length And (Mid(pattern, patternPos, 1) = "*"))
					patternPos:+ 1
				Wend
				patternPos:- 1
				
				' Check matches
				While (stringPos < fileName.length)
					
					If (match(pattern, patternPos, fileName, stringPos, flags)) Then
						Return True
					EndIf
						
					If (Mid(fileName, stringPos, 1) = "/" And (flags & FNM_FILE_NAME)) Then
						Exit
					EndIf
					
					stringPos:+ 1
				Wend
				
				Return False
			
			Default
				If patternChar <> stringChar Then Return False
			
		End Select
		
		stringPos  = stringPos + 1  ; stringChar$ = Mid(fileName, stringPos, 1)
		
		' If we're at the end of the filename, but not the pattern, then it didn't match
		If stringPos > fileName.Length And patternPos < pattern.Length Then	Return False
		
	Until patternPos > Len(pattern)
	
	Return True
	
End Function
