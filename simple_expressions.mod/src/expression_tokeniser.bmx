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

	' -- Options
	Field ignoreWhitespace:Byte         '''< Is whitespace ignored?

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

	Method getExpressionText:String()
		Return Self._expressionText
	End Method


	' ------------------------------------------------------------
	' -- Main API methods
	' ------------------------------------------------------------

	''' <summary>Move the to the next token and return it.</summary>
	Method getNextToken:Byte()

		' TODO: Cache the next character (via peekChar)? It's used a lot

		' TODO: Should this really throw an error?
		If Self.currentToken = TOKEN_EOF Then
			Throw "End of file reached"
		EndIf

		' Skip whitespace characters if they're being ignored.
		If Self.ignoreWhitespace Then
			Self._skipWhitespace()
		EndIf

		' Check for end of file.
		If Self._peekChar() = 0 Then
			Self.currentToken = TOKEN_EOF
			Return 0
		EndIf

		' Get next character
		Local charCode:Byte = Self._readChar()
		Local char:String   = CHAR_LOOKUP[charCode]

		' TODO: May remove this completely
		If Self.ignoreWhitespace = False And CharHelper.IsAsciiWhitespace(charCode) Then

			Local curString:String
			Local ch2:Byte

			While (ch2 = Self._peekChar()) <> 0

				If Not CharHelper.IsAsciiWhitespace(ch2) Then
					Exit
				EndIf

				curString:String = curString:String + CHAR_LOOKUP[ch2]
				Self._readChar()

				Self.currentToken	= TOKEN_WHITESPACE
				Self.tokenText		= curString:String

			Wend

			Return 0

		EndIf

		' Read numbers
		If CharHelper.IsAsciiDigit(charCode) Then

			Self.currentToken = TOKEN_NUMBER

			' Read the number.
			Local s:String = char

			While Self._peekChar() <> 0
				charCode = Self._peekChar()

				If CharHelper.IsAsciiDigit(charCode)
					s :+ CHAR_LOOKUP[Self._readChar()]
				Else
					Exit
				EndIf
			Wend

			Self.tokenText = s

			Return 0

		EndIf

		' Read strings
		If charCode = ASC_APOSTROPHE Then
			Self._readString()
			Return 0
		EndIf

		' Read keywords
		If charCode = ASC_UNDERSCORE Or CharHelper.IsAsciiLetter(charCode) Then

			Self.currentToken = TOKEN_KEYWORD
			Local s:String    = char

			Local nextChar:Byte = Self._peekChar()
			While nextChar <> 0
				If nextChar = ASC_UNDERSCORE Or nextChar = ASC_MINUS Or CharHelper.IsAsciiLetterOrDigit(nextChar) Then
					s = s + CHAR_LOOKUP[Self._readChar()]
				Else
					Exit
				EndIf

nextChar = Self._peekChar()

			Wend

			Self.TokenText	= s
			Return 0

		EndIf

		' Read double character operators
		Local nextChar:Byte = Self._peekChar()

		' Double colon - namespace seperator
		If (charCode = ASC_COLON And nextChar = ASC_COLON) Then
			Self.currentToken	= TOKEN_DOUBLE_COLON
			Self.tokenText		= "::"
			Self._readChar()
			Return 0
		EndIf

		' Not equal
		If charCode = ASC_EXCLAMATION And nextChar = ASC_EQUALS Then
			Self.currentToken	= TOKEN_NOT_EQUAL
			Self.tokenText		= "!="
			Self._readChar()
			Return 0
		EndIf

		' Not equal (alternative)
		If charCode = ASC_LESS_THAN And nextChar = ASC_GREATER_THAN Then
			Self.currentToken	= TOKEN_NOT_EQUAL
			Self.tokenText		= "<>"
			Self._readChar()
			Return 0
		EndIf

		' Equal (C++ style)
		If charCode = ASC_EQUALS And nextChar = ASC_EQUALS Then
			Self.currentToken	= TOKEN_EQUAL
			Self.tokenText		= "=="
			Self._readChar()
			Return 0
		EndIf

		' Less than equal (<=)
		If charCode = ASC_LESS_THAN And nextChar = ASC_EQUALS Then
			Self.currentToken	= TOKEN_LE
			Self.tokenText		= "<="
			Self._readChar()
			Return 0
		EndIf

		' Greater than equal (>=)
		If charCode = ASC_GREATER_THAN And nextChar = ASC_EQUALS Then
			Self.currentToken	= TOKEN_GE
			Self.tokenText		= ">="
			Self._readChar()
			Return 0
		EndIf

		Self.tokenText    = char
		Self.currentToken = TOKEN_PUNCTUATION

		' Convert token types
		If charCode >= 32 And charCode <= 128 Then
			Self.currentToken = ExpressionTokeniser.CharToToken(char)
		EndIf

		Return Self.currentToken

	End Method

	''' <summary>Checks if the current token is a reserved keyword.</summary>
	''' <param name="word">The word to check against.</param>
	''' <returns>True if a keyword, false if not.</returns>
	Method isKeyword:Int(word:String)
		Return (Self.CurrentToken = TOKEN_KEYWORD And Self.TokenText = word)
	End Method

	Method isRelationalOperator:Byte()

		Local result:Byte = False

		' TODO: Not the prettiest. Tidy it up.
		Select Self.currentToken
			Case TOKEN_EQUAL     ; result = True
			Case TOKEN_NOT_EQUAL ; result = True
			Case TOKEN_LT        ; result = True
			Case TOKEN_GT        ; result = True
			Case TOKEN_LE        ; result = True
			Case TOKEN_GE        ; result = True
		End Select

		Return result

	End Method

	''' <summary>Gets the TokenType for a character.</summary>
	''' <oaram name="charValue">The character to lookup.</param>
	''' <returns>TokenType value.</returns>
	Function CharToToken:Byte(charValue:String)

		Select charValue

			Case "+"		; Return TOKEN_PLUS
			Case "-"		; Return TOKEN_MINUS
			Case "*"		; Return TOKEN_MUL
			Case "/"		; Return TOKEN_DIV
			Case "%"		; Return TOKEN_MOD
			Case "<"		; Return TOKEN_LT
			Case ">"		; Return TOKEN_GT
			Case "("		; Return TOKEN_LEFT_PAREN
			Case ")"		; Return TOKEN_RIGHT_PAREN
			Case "{"		; Return TOKEN_LEFT_CURLY_BRACE
			Case "}"		; Return TOKEN_RIGHT_CURLY_BRACE
			Case "!"		; Return TOKEN_NOT
			Case "$"		; Return TOKEN_DOLLAR
			Case ","		; Return TOKEN_COMMA
			Case "."		; Return TOKEN_DOT

		End Select

		' -- Default to punctuation
		Return TOKEN_PUNCTUATION

	End Function


	' ------------------------------------------------------------
	' -- Internal tokenising methods
	' ------------------------------------------------------------

	Method _setCurrentToken(tokenType:Byte, tokenText:String)
		Self.currentToken = tokenType
		Self.tokenText    = tokenText
	End Method

	Method _readString:String()
		Local s:String      = ""
		Local charCode:Byte = Self._peekChar()

		While charCode <> 0
			If charCode = ASC_APOSTROPHE Then
				' Skip past the end of the string
				Self._readChar()
				Exit
			Else
				s :+ CHAR_LOOKUP[Self._readChar()]
			EndIf

			charCode = Self._peekChar()
		Wend

		Self._setCurrentToken(TOKEN_STRING, s)

		Return s

	End Method

	''' <summary>Moves to the next character in the expression and returns its ascii value.</summary>
	Method _readChar:Byte()
		Local charValue:Int = Self._peekChar()

		Self.CurrentPosition:+ 1

		Return charValue
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

		' Setup rules.
		Self.ignoreWhitespace    = True

		' Start tokenising
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
