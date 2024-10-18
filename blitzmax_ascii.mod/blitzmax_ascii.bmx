' ------------------------------------------------------------------------------
' -- sodaware.blitzmax_ascii
' --
' -- Constant values for the first 128 characters of the ASCII character 
' -- set.  Useful for removing magic numbers when using the "Chr" and "Asc" 
' -- commands.
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


' --------------------------------------------------
' -- Quick Reference
' --------------------------------------------------

' Alphabet and numbers:
'	A - Z = ASC_A_UPPERCASE to ASC_Z_UPPERCASE
'	a - z = ASC_a to ASC_z
'	0 - 9 = ASC_0 to ASC_9

' Brackets:
'	( )   = ASC_BRACKET_OPEN and ASC_BRACKET_CLOSE
'	[ ]   = ASC_SQUARE_OPEN and ASC_SQUARE_CLOSE
'	{ }   = ASC_CURLY_OPEN and ASC_CURLY_CLOSE
'	< >   = ASC_CHEVRON_OPEN and ASC_CHEVRON_CLOSE
'	       (or ASC_LESS_THAN and ASC_GREATER_THAN)

' Other useful characters:
'	ASC_QUOTE	- Quotation mark
'	ASC_TAB		- Tab
'	ASC_AT		- @
'	ASC_CARET	- ^
'	ASC_GRAVE	- `

' Line endings:
'  Windows uses a carriage return followed by a line feed.
'  Linux uses just a line feed
'	ASC_CR 		- Carriage Return
'	ASC_LF		- Line feed


Strict

Module sodaware.blitzmax_ascii

' --------------------------------------------------
' -- Non-Visible formatting characters
' --------------------------------------------------

Const ASC_NULL:Byte     = 0     ''' Null character
Const ASC_SOH:Byte      = 1     ''' Start of Heading
Const ASC_STX:Byte      = 2     ''' Start of Text
Const ASC_ETX:Byte      = 3     ''' End of Text
Const ASC_EOT:Byte      = 4     ''' End of Transmission
Const ASC_ENQ:Byte      = 5     ''' Enquiry
Const ASC_ACK:Byte      = 6     ''' Acknowledge
Const ASC_BEL:Byte      = 7     ''' Bell
Const ASC_BS:Byte       = 8     ''' Backspace
Const ASC_TAB:Byte      = 9     ''' Tab
Const ASC_LF			= 10	''' Line Feed
Const ASC_VT			= 11	''' Vertical Tab
Const ASC_FF			= 12	''' Form Feed
Const ASC_CR			= 13	''' Carriage Return
Const ASC_SO			= 14	''' Shift Out
Const ASC_SI			= 15	''' Shift In
Const ASC_DLE			= 16	''' Data Link Escape
Const ASC_DC1			= 17	''' Device Control 1
Const ASC_DC2			= 18	''' Device Control 2
Const ASC_DC3			= 19	''' Device Control 3
Const ASC_DC4			= 20	''' Device Control 4
Const ASC_NAK			= 21	''' Negative Acknowledgement
Const ASC_SYN			= 22	''' Synchronouse Idle
Const ASC_ETB			= 23	''' End of Transmission Block
Const ASC_CAN			= 24	''' Cancel
Const ASC_EM			= 25	''' End of Medium
Const ASC_SUB			= 26	''' Substitute
Const ASC_ESC			= 27	''' Escape
Const ASC_FS			= 28	''' File Separator
Const ASC_GS			= 29	''' Group Separator
Const ASC_RS			= 30	''' Record Separator
Const ASC_US			= 31	''' Unit Separator
Const ASC_SPACE			= 32    ''' Space

' --------------------------------------------------
' -- Common Punctuation
' --------------------------------------------------

Const ASC_EXCLAMATION	= 33
Const ASC_QUOTE			= 34
Const ASC_HASH			= 35
Const ASC_POUND         = 35
Const ASC_DOLLAR        = 36
Const ASC_PERCENT		= 37
Const ASC_AMPERSAND		= 38
Const ASC_APOSTROPHE	= 39
Const ASC_BRACKET_OPEN	= 40
Const ASC_BRACKET_CLOSE = 41
Const ASC_ASTERISK		= 42
Const ASC_PLUS			= 43
Const ASC_COMMA			= 44
Const ASC_MINUS			= 45
Const ASC_PERIOD		= 46
Const ASC_FORWARD_SLASH	= 47

' --------------------------------------------------
' -- Digits
' --------------------------------------------------

Const ASC_0				= 48
Const ASC_1				= 49
Const ASC_2				= 50
Const ASC_3				= 51
Const ASC_4				= 52
Const ASC_5				= 53
Const ASC_6				= 54
Const ASC_7				= 55
Const ASC_8				= 56
Const ASC_9				= 57

' --------------------------------------------------
' -- More Punctuation
' --------------------------------------------------

Const ASC_COLON			= 58
Const ASC_SEMI_COLON	= 59
Const ASC_CHEVRON_OPEN	= 60 ; Const ASC_LESS_THAN = 60
Const ASC_EQUALS		= 61
Const ASC_CHEVRON_CLOSE	= 62 ; Const ASC_GREATER_THAN = 62
Const ASC_QUESTION		= 63
Const ASC_AT			= 64

' --------------------------------------------------
' -- Uppercase alphabet
' --------------------------------------------------

Const ASC_A_UPPERCASE	= 65
Const ASC_B_UPPERCASE	= 66
Const ASC_C_UPPERCASE	= 67
Const ASC_D_UPPERCASE	= 68
Const ASC_E_UPPERCASE	= 69
Const ASC_F_UPPERCASE	= 70
Const ASC_G_UPPERCASE	= 71
Const ASC_H_UPPERCASE	= 72
Const ASC_I_UPPERCASE	= 73
Const ASC_J_UPPERCASE	= 74
Const ASC_K_UPPERCASE	= 75
Const ASC_L_UPPERCASE	= 76
Const ASC_M_UPPERCASE	= 77
Const ASC_N_UPPERCASE	= 78
Const ASC_O_UPPERCASE	= 79
Const ASC_P_UPPERCASE	= 80
Const ASC_Q_UPPERCASE	= 81
Const ASC_R_UPPERCASE	= 82
Const ASC_S_UPPERCASE	= 83
Const ASC_T_UPPERCASE	= 84
Const ASC_U_UPPERCASE	= 85
Const ASC_V_UPPERCASE	= 86
Const ASC_W_UPPERCASE	= 87
Const ASC_X_UPPERCASE	= 88
Const ASC_Y_UPPERCASE	= 89
Const ASC_Z_UPPERCASE	= 90

' --------------------------------------------------
' -- Brackets and slashes
' --------------------------------------------------

Const ASC_SQUARE_OPEN	= 91
Const ASC_BACKSLASH		= 92
Const ASC_SQUARE_CLOSE	= 93
Const ASC_CARET			= 94	''' ^ symbol
Const ASC_UNDERSCORE	= 95
Const ASC_GRAVE			= 96	''' ` symbol

' --------------------------------------------------
' -- Lowercase alphabet
' --------------------------------------------------

Const ASC_a				= 97
Const ASC_b				= 98
Const ASC_c				= 99
Const ASC_d				= 100
Const ASC_e				= 101
Const ASC_f				= 102
Const ASC_g				= 103
Const ASC_h				= 104
Const ASC_i				= 105
Const ASC_j				= 106
Const ASC_k				= 107
Const ASC_l				= 108
Const ASC_m				= 109
Const ASC_n				= 110
Const ASC_o				= 111
Const ASC_p				= 112
Const ASC_q				= 113
Const ASC_r				= 114
Const ASC_s				= 115
Const ASC_t				= 116
Const ASC_u				= 117
Const ASC_v				= 118
Const ASC_w				= 119
Const ASC_x				= 120
Const ASC_y				= 121
Const ASC_z				= 122

' --------------------------------------------------
' -- Curly brackets and miscellaneous
' --------------------------------------------------

Const ASC_CURLY_OPEN	= 123
Const ASC_PIPE			= 124	''' | symbol
Const ASC_CURLY_CLOSE	= 125	
Const ASC_TILDE			= 126	''' ~ symbol
Const ASC_DELETE		= 127
