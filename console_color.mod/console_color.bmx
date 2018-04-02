' ------------------------------------------------------------------------------
' -- sodaware.console_color
' --
' -- Adds cross-platform support for colours in command line applications, using 
' -- colour codes and special output commands.
' -- 
' -- Based on http://pear.php.net/package/Console_Color
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


Module sodaware.Console_Color

ModuleInfo "Version: 0.1.0"
ModuleInfo "Author: Phil Newton"

SuperStrict

Rem

NOTE: Some of these styles only work on ANSI terminals.

Colour codes

| Color   | Text normal | Text bold | Background |
|---------+-------------+-----------+------------|
| Black   | %k          | %K        | %0         |
| Red     | %r          | %R        | %1         |
| Green   | %g          | %G        | %2         |
| Yellow  | %y          | %Y        | %3         |
| Blue    | %b          | %B        | %4         |
| Magenta | %m          | %M        | %5         |
| Purple  | %p          | %P        |            |
| Cyan    | %c          | %C        | %6         |
| White   | %w          | %W        | %7         |

Style codes

| Style              | Code   |
|--------------------+--------|
| Blinking, flashing | %F     |
| Underline          | %U     |
| Invert, reverse    | %8     |
| Bold               | %_, %9 |
| Reset color        | %n     |
| Single %           | %%     |

EndRem

Import brl.standardio

?Win32 
Include "src/console_color_win32.bmx"
?Not Win32
Include "src/console_color_ansi.bmx"
?

Public

Function Console_Color_DisableFormatting()
?Win32
	Console_Color_Win32.DisableFormatting()
?Not Win32
	Console_Color_ANSI.DisableFormatting()
?
End Function

Function Console_Color_EnableFormatting()
?Win32
	Console_Color_Win32.EnableFormatting()
?Not Win32
	Console_Color_ANSI.EnableFormatting()
?
End Function


''' <summary>Write a string to the console that contains colourized information.</summary>
''' <param name="str">The string to display.</param>
Function WriteC(str:String = "")
	
?Win32
	Console_Color_Win32.Write(str)
?Not win32	
	Console_Color_ANSI.Write(str)
?

End Function

''' <summary>
''' Write a string to the console that contains colourized information and move to 
''' the next line.
''' </summary>
''' <param name="str">The string to display.</param>
Function PrintC(str:String = "")
	WriteC(str + "~n")
End Function
