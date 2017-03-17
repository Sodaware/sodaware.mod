' ------------------------------------------------------------------------------
' -- src/console_color_win32.bmx
' --
' -- Internal driver for Win32 consoles.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Private

' Only for Windows
Extern "Win32"
	Function SetConsoleTextAttribute:Int(hConsoleOutput:Int Ptr,wAttributes:Int)
	Function GetStdHandle:Int Ptr(nStdHandle:Int)
	Function SetConsoleCursorPosition:Int(hConsoleOutput:Int Ptr, wAttributes:Int)
End Extern


Const COLOR_BLACK:Int 	= $0000
Const COLOR_BLUE:Int 	= $0001
Const COLOR_GREEN:Int 	= $0002 
Const COLOR_CYAN:Int 	= $0003
Const COLOR_RED:Int		= $0004
Const COLOR_MAGENTA:Int	= $0005
const COLOR_PURPLE:Int	= $0005
Const COLOR_YELLOW:Int 	= $0006
Const COLOR_GREY:Int 	= $0007
Const COLOR_WHITE:Int 	= $0008

Const STD_OUTPUT_HANDLE:Int = -11;

Type Console_Color_Win32
	
	Global s_CurrentBackground:Int
	Global s_CurrentForeground:Int
	
	' -- Two lookup tables for foreground and background. We find the index of the code in the lookup 
	' -- string, and use it to get the color from the relevant table. 
	' -- It's not the nicest code ever, but it's preferable to a long list of "If code = x then set color y" 
	' -- statements.
	Const FOREGROUND_LOOKUP:String = "krgybmpcwKRGYBMPCW"
	Const BACKGROUND_LOOKUP:String = "01234567"
	
	Global FOREGROUND_TABLE:Int[] = [COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_BLUE, COLOR_MAGENTA, COLOR_PURPLE, COLOR_CYAN, COLOR_WHITE, COLOR_BLACK + COLOR_WHITE, COLOR_RED + COLOR_WHITE, COLOR_GREEN + COLOR_WHITE, COLOR_YELLOW + COLOR_WHITE, COLOR_BLUE + COLOR_WHITE, COLOR_MAGENTA + COLOR_WHITE, COLOR_PURPLE + COLOR_WHITE, COLOR_CYAN + COLOR_WHITE, COLOR_WHITE + COLOR_WHITE]
	Global BACKGROUND_TABLE:Int[] = [COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_BLUE, COLOR_MAGENTA, COLOR_CYAN, COLOR_WHITE]

	Function Write(str:String)
		
		Local strPos:Int = 0
		Local strLen:Int = str.Length - 1
		Local output:String = ""
	
		For strpos = 0 To strlen
			Local curChar:String = Chr(str[strpos])
			
			If curchar = "%" And strpos < (strlen) Then
				
				StandardIOStream.WriteString(output)
				output = ""
			
				Local nextChar:String = Chr(str[strpos + 1])
				
				if nextChar = "%" then
					output = output + "%"
				elseIf nextChar = "n" Then
					' -- Reset
					Console_Color_Win32.s_CurrentForeground = COLOR_GREY; Console_Color_Win32.s_CurrentBackground = COLOR_BLACK
				ElseIf Console_Color_Win32.FOREGROUND_LOOKUP.Contains(nextChar) Then
					' -- Foreground
					Console_Color_Win32.s_CurrentForeground = Console_Color_Win32.FOREGROUND_TABLE[Console_Color_Win32.FOREGROUND_LOOKUP.Find(nextChar)]
				ElseIf Console_Color_Win32.BACKGROUND_LOOKUP.Contains(nextChar) Then
					' -- Background
					Console_Color_Win32.s_CurrentBackground = Console_Color_Win32.BACKGROUND_TABLE[Console_Color_Win32.BACKGROUND_LOOKUP.Find(nextChar)]
				End If
				
				SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), Console_Color_Win32.s_CurrentForeground | (Console_Color_Win32.s_CurrentBackground Shl 4))
				
				strpos = strpos + 1
				
			Else
				output = output + curchar
			End If
		Next
		
		StandardIOStream.WriteString(output)
		StandardIOStream.Flush()
		
	End Function
	
End Type
