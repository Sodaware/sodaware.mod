' ------------------------------------------------------------------------------
' -- src/expression_tokeniser.bmx
' --
' -- Converts a string expression into tokens. These tokens are then used by
' -- the expression evaluator during execution.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2018 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.retro
Import sodaware.blitzmax_ascii
Import "char_helper.bmx"

''' <summary>Class for tokenising strings into something usable.</summary>
Type ExpressionTokeniser

	' Character lookup table (faster than `Chr`)
	Global CHAR_LOOKUP:String[256]

	' List of valid tokens
	Const TOKEN_BOF:Byte                = 1
	Const TOKEN_EOF:Byte                = 2
	Const TOKEN_NUMBER:Byte             = 3
	Const TOKEN_STRING:Byte             = 4
	Const TOKEN_KEYWORD:Byte            = 5
	Const TOKEN_EQUAL:Byte              = 6
	Const TOKEN_NOT_EQUAL:Byte          = 7
	Const TOKEN_LT:Byte                 = 8
	Const TOKEN_GT:Byte                 = 9
	Const TOKEN_LE:Byte                 = 11
	Const TOKEN_GE:Byte                 = 12
	Const TOKEN_PLUS:Byte               = 13
	Const TOKEN_MINUS:Byte              = 14
	Const TOKEN_MUL:Byte                = 15
	Const TOKEN_DIV:Byte                = 16
	Const TOKEN_MOD:Byte                = 17
	Const TOKEN_LEFT_PAREN:Byte         = 18
	Const TOKEN_RIGHT_PAREN:Byte        = 19
	Const TOKEN_LEFT_CURLY_BRACE:Byte   = 20
	Const TOKEN_RIGHT_CURLY_BRACE:Byte  = 21
	Const TOKEN_NOT:Byte                = 22
	Const TOKEN_PUNCTUATION:Byte        = 23
	Const TOKEN_WHITESPACE:Byte         = 24
	Const TOKEN_DOLLAR:Byte             = 25
	Const TOKEN_COMMA:Byte              = 26
	Const TOKEN_DOT:Byte                = 27
	Const TOKEN_DOUBLE_COLON:Byte       = 28

	' -- Current token info.
	Field currentToken:Byte             '''< Const TokenType for current token
	Field tokenText:String              '''< Text of the current token
	Field currentPosition:Int           '''< Current position within the expression

	' -- Internal fields.
	Field _expressionText:String        '''< The full text of the expression


	' ------------------------------------------------------------
	' -- Configuring
	' ------------------------------------------------------------

	''' <summary>Set the expression to be tokenised.</summary>
	''' <param name="expression">The expression to tokenise.</param>
	Method setExpression(expression:String)
		Self._expressionText = expression
		Self.currentPosition = 0
		Self.currentToken    = TOKEN_BOF
	End Method


	' ------------------------------------------------------------
	' -- Public Getters
	' ------------------------------------------------------------

	''' <summary>Get the text of the current expression being tokenised.</summary>
	Method getExpressionText:String()
		Return Self._expressionText
	End Method


	' ------------------------------------------------------------
	' -- Main API methods
	' ------------------------------------------------------------

	''' <summary>Move to the next token and return it.</summary>
	''' <return>Token value. Will be one of the `TOKEN_` constants.</return>
	Method getNextToken:Byte()

		' TODO: Should this really throw an error?
		If Self.currentToken = TOKEN_EOF Then
			Throw "End of file reached"
		EndIf

		' Skip any whitespace characters.
		Self._skipWhitespace()

		' Check for end of file.
		If Self._peekChar() = 0 Then
			Self.currentToken = TOKEN_EOF
			Return 0
		EndIf

		' Read the next character.
		Local charCode:Byte = Self._readChar()
		Local char:String   = CHAR_LOOKUP[charCode]

		' Read strings.
		If charCode = ASC_APOSTROPHE Then
			Self._readString()
			Return 0
		EndIf

		' Read numbers.
		If charCode >= ASC_0 And charCode =< ASC_9 Then
			Self.currentToken = TOKEN_NUMBER
			Self.tokenText    = CHAR_LOOKUP[charCode]

			' Read everything until the end of the digit.
			charCode = Self._peekChar()
			While charCode <> 0
				' End of number
				If charCode < ASC_0 or charCode > ASC_9 Then Exit

				Self.tokenText :+ CHAR_LOOKUP[charCode]
				charCode = Self._nextChar()
			Wend

			Return 0
		EndIf

		' Read keywords.
		If charCode = ASC_UNDERSCORE Or CharHelper.IsAsciiLetter(charCode) Then
			Self.currentToken = TOKEN_KEYWORD
			Self.tokenText    = char

			charCode = Self._peekChar()
			While charCode <> 0
				If charCode = ASC_UNDERSCORE Or charCode = ASC_MINUS Or CharHelper.IsAsciiLetterOrDigit(charCode) Then
					Self.tokenText :+ CHAR_LOOKUP[charCode]
				Else
					Exit
				EndIf

				charCode = Self._nextChar()
			Wend

			' Check for language keywords.
			Select Self.tokenText.toLower()
				Case "not"
					Self.currentToken = TOKEN_NOT
			End Select

			Return 0
		EndIf

		' Read double character operators
		Local nextChar:Byte = Self._peekChar()

		If charCode = ASC_COLON And nextChar = ASC_COLON Then
			' :: - namespace seperator
			Self.currentToken	= TOKEN_DOUBLE_COLON
			Self.tokenText		= "::"
			Self._readChar()
			Return 0
		ElseIf charCode = ASC_EXCLAMATION And nextChar = ASC_EQUALS Then
			' != - Not equal to
			Self.currentToken	= TOKEN_NOT_EQUAL
			Self.tokenText		= "!="
			Self._readChar()
			Return 0
		ElseIf charCode = ASC_LESS_THAN And nextChar = ASC_GREATER_THAN Then
			' <> - Not equal to
			Self.currentToken	= TOKEN_NOT_EQUAL
			Self.tokenText		= "<>"
			Self._readChar()
			Return 0
		ElseIf charCode = ASC_EQUALS And nextChar = ASC_EQUALS Then
			' == - Equal (C++ style)
			Self.currentToken	= TOKEN_EQUAL
			Self.tokenText		= "=="
			Self._readChar()
			Return 0
		ElseIf charCode = ASC_LESS_THAN And nextChar = ASC_EQUALS Then
			' <= - Less than equal
			Self._setCurrentToken(TOKEN_LE, "<=")
			Self._readChar()
			Return 0
		ElseIf charCode = ASC_GREATER_THAN And nextChar = ASC_EQUALS Then
			' >= - Greater than equal
			Self._setCurrentToken(TOKEN_GE, ">=")
			Self._readChar()
			Return 0
		EndIf

		' NOT shortcode
		If charCode = ASC_EXCLAMATION Then
			Return Self._setCurrentToken(TOKEN_NOT, "!")
		EndIf

		' Nothing else matches - treat as punctuation.
		Self.tokenText    = char
		Self.currentToken = Self.charToToken(charCode)

		Return Self.currentToken

	End Method

	''' <summary>Checks if the current token is a reserved keyword.</summary>
	''' <param name="word">The word to check against.</param>
	''' <returns>True if a keyword, false if not.</returns>
	Method isKeyword:Byte(word:String)
		Return (Self.currentToken = TOKEN_KEYWORD And Self.tokenText = word)
	End Method

	Method isRelationalOperator:Byte()
		Select Self.currentToken
			Case TOKEN_EQUAL     ; Return True
			Case TOKEN_NOT_EQUAL ; Return True
			Case TOKEN_LT        ; Return True
			Case TOKEN_GT        ; Return True
			Case TOKEN_LE        ; Return True
			Case TOKEN_GE        ; Return True
		End Select

		Return False
	End Method

	Method isNameToken:Byte()
		Select Self.currentToken
			Case TOKEN_DOT     ; Return True
			Case TOKEN_MINUS   ; Return True
			Case TOKEN_KEYWORD ; Return True
			Case TOKEN_NUMBER  ; Return True
		end Select
	End Method

	''' <summary>Gets the TokenType for a character.</summary>
	''' <oaram name="code">The character code.</param>
	''' <returns>TokenType value.</returns>
	Method charToToken:Byte(charCode:Byte)

		Select charCode

			Case ASC_PLUS           ; Return TOKEN_PLUS
			Case ASC_MINUS          ; Return TOKEN_MINUS
			Case ASC_ASTERISK       ; Return TOKEN_MUL
			Case ASC_FORWARD_SLASH  ; Return TOKEN_DIV
			Case ASC_COMMA          ; Return TOKEN_COMMA
			Case ASC_PERIOD         ; Return TOKEN_DOT
			Case ASC_BRACKET_OPEN   ; Return TOKEN_LEFT_PAREN
			Case ASC_BRACKET_CLOSE  ; Return TOKEN_RIGHT_PAREN
			Case ASC_PERCENT        ; Return TOKEN_MOD
			Case ASC_LESS_THAN      ; Return TOKEN_LT
			Case ASC_GREATER_THAN   ; Return TOKEN_GT
			Case ASC_CURLY_OPEN     ; Return TOKEN_LEFT_CURLY_BRACE
			Case ASC_CURLY_CLOSE    ; Return TOKEN_RIGHT_CURLY_BRACE
			Case ASC_EXCLAMATION    ; Return TOKEN_NOT
			Case ASC_DOLLAR         ; Return TOKEN_DOLLAR

		End Select

		' -- Default to punctuation
		Return TOKEN_PUNCTUATION

	End Method


	' ------------------------------------------------------------
	' -- Internal tokenising methods
	' ------------------------------------------------------------

	Method _setCurrentToken:Byte(tokenType:Byte, tokenText:String)
		Self.currentToken = tokenType
		Self.tokenText    = tokenText

		Return tokenType
	End Method

	Method _readString:String()
		Local s:String      = ""
		Local charCode:Byte = Self._peekChar()
		Local readChar:Byte

		While charCode <> 0
			If charCode = ASC_APOSTROPHE Then
				' Skip past the end of the string
				Self._readChar()
				Exit
			Else
				' Don't try and shorten this to:
				' `s :+ CHAR_LOOKUP[Self._readChar()]`
				' It will not work on bmx-ng.
				readChar = Self._readChar()
				s :+ CHAR_LOOKUP[readChar]
			EndIf

			charCode = Self._peekChar()
		Wend

		Self._setCurrentToken(TOKEN_STRING, s)

		Return s
	End Method

	''' <summary>Read the current character and move to the next position.</summary>
	Method _readChar:Byte()
		Self.currentPosition:+ 1
		Return Self._expressionText[Self.currentPosition - 1]
	End Method

	Method _peekChar:Byte()
		' Return `0` Byte if at the end of the expression
		If Self.CurrentPosition >= Self._expressionText.Length Then Return 0

		Return Self._expressionText[Self.currentPosition]
	End Method

	' Move to the next character and return it.
	Method _nextChar:Byte()
		Self.CurrentPosition:+ 1
		Return Self._peekChar()
	End Method

	''' <summary>Reads all whitespace characters until the next non-whitespace character.</summary>
	Method _skipWhitespace()
		Local currentChar:Byte = Self._peekChar()
		While currentChar > 0 And currentChar <= 32
			currentChar = Self._nextChar()
		Wend
	End Method

	Method reset()
		Self.getNextToken()
	End Method


	' ------------------------------------------------------------
	' -- Creation and Destruction
	' ------------------------------------------------------------

	Function Create:ExpressionTokeniser(expression:String)

		Local this:ExpressionTokeniser = New ExpressionTokeniser

		' Initialise expression.
		this.setExpression(expression)
		this.reset()

		Return this

	End Function

End Type

Private

ExpressionTokeniser.CHAR_LOOKUP = New String[256]

For Local i:Int = 0 To 255
	ExpressionTokeniser.CHAR_LOOKUP[i] = Chr(i)
Next

Public
