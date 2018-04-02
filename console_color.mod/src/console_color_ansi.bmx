' ------------------------------------------------------------------------------
' -- src/console_color_ansi.bmx
' --
' -- Internal driver for consoles that use ANSI codes (linux/mac).
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


Private

Const COLOR_BLACK:Int   = 30
Const COLOR_RED:Int     = 31
Const COLOR_GREEN:Int   = 32
Const COLOR_YELLOW:Int  = 33
Const COLOR_BLUE:Int    = 34
Const COLOR_MAGENTA:Int = 35
Const COLOR_CYAN:Int    = 36
Const COLOR_WHITE:Int   = 37
Const COLOR_PURPLE:Int  = 35
Const COLOR_GREY:Int    = 37
Const COLOR_CLEAR:Int   = 40

Const BACKGROUND_OFFSET:Int	= 10

Type Console_Color_ANSI

    ' -- Options
    Global s_IsEnabled:Byte         = True

	' -- Current style
	Global s_IsBold:Int             = False
	Global s_IsUnderline:Int        = False
	Global s_IsBlink:Int            = False
	Global s_IsHidden:Int           = False
	Global s_CurrentForeground:Int  = COLOR_WHITE
	Global s_CurrentBackground:Int  = COLOR_CLEAR
	
	Const FOREGROUND_LOOKUP:String  = "krgybmpcw"
	Global FOREGROUND_TABLE:Int[]   = [COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_BLUE, COLOR_MAGENTA, COLOR_PURPLE, COLOR_CYAN, COLOR_WHITE]
	Const BACKGROUND_LOOKUP:String  = "01234567"
	Global BACKGROUND_TABLE:Int[]   = [COLOR_BLACK, COLOR_RED, COLOR_GREEN, COLOR_YELLOW, COLOR_BLUE, COLOR_MAGENTA, COLOR_CYAN, COLOR_WHITE]

    Function EnableFormatting()
        Console_Color_ANSI.s_IsEnabled = True
    End Function

    Function DisableFormatting()
        Console_Color_ANSI.s_IsEnabled = False
    End Function

	Function Write(str:String)
		
		StandardIOStream.WriteString(Console_Color_ANSI.Convert(str))
		StandardIOStream.Flush()
		
	End Function
	
	Function Convert:String(str:String)
		
		Local strPos:Int = 0
		Local strLen:Int = str.Length - 1
		Local output:String = ""
	
		For strpos = 0 To strlen
			Local curChar:String = Chr(str[strpos])
			
			If curchar = "%" And strpos < (strlen) Then
				
				Local nextChar:String = Chr(str[strpos + 1])
				
				If nextChar = "n" Then
					
					Console_Color_ANSI.s_CurrentForeground = COLOR_WHITE 
					Console_Color_ANSI.s_CurrentBackground = COLOR_CLEAR
					Console_Color_ANSI.s_IsBold = false
					Console_Color_ANSI.s_IsUnderline = false
					Console_Color_ANSI.s_IsBlink = false
					
				ElseIf Console_Color_ANSI.FOREGROUND_LOOKUP.Contains(nextChar.ToLower()) Then
					
					' -- Foreground
					Console_Color_ANSI.s_CurrentForeground = Console_Color_ANSI.FOREGROUND_TABLE[Console_Color_ANSI.FOREGROUND_LOOKUP.Find(nextChar.ToLower())]
					if nextChar = nextChar.ToUpper() then Console_Color_ANSI.s_IsBold = true else Console_Color_ANSI.s_IsBold = false
					
				ElseIf Console_Color_ANSI.BACKGROUND_LOOKUP.Contains(nextChar) Then
					' -- Background
					Console_Color_ANSI.s_CurrentBackground = Console_Color_ANSI.BACKGROUND_TABLE[Console_Color_ANSI.BACKGROUND_LOOKUP.Find(nextChar.ToLower())]
				else
					' -- Styles
					Select nextChar
						case "F"; Console_Color_ANSI.s_IsBlink = true;
						case "U"; Console_Color_ANSI.s_IsUnderline = true;
					End Select
				
				End If
				
				
				if nextChar = "%" then
					output:+output
				else
					' Create output code
					local ansiCode:String	= chr(27) + "[0;"
				
					if Console_Color_ANSI.s_IsBold then ansiCode:+ "1;"
					if Console_Color_ANSI.s_IsBlink then ansiCode:+ "5;"
					if Console_Color_ANSI.s_IsUnderline then ansiCode:+ "4;"
					
					ansiCode:+ (Console_Color_ANSI.s_CurrentForeground) + ";"
					ansiCode:+ (Console_Color_ANSI.s_CurrentBackground + background_offset) + "m"

                    If Console_Color_Ansi.s_IsEnabled Then
                        output:+ ansiCode
                    EndIf
					strpos = strpos + 1
				endif
			Else
				output = output + curchar
			End If
		Next
		
		Return output
		
	End Function
	
End Type
