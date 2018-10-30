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
Import "char_helper.bmx"

''' <summary>Class for tokenising strings into something usable.</summary>
Type ExpressionTokeniser

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
	Field singleCharacterMode:Byte      '''< Is every single char treated as a token?

	' -- Current Token info
	Field currentToken:Byte             '''< Const TokenType for current token
	Field tokenText:String              '''< Text of the current token
	Field currentPosition:Int           '''< Current position within the expression

	' -- Internal fields
	Field _expressionText:String        '''< The full text of the expression


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
	Method getNextToken:Int()

		' TODO: Should this really throw an error?
		If self.currentToken = TOKEN_EOF Then
			Throw "End of file reached"
		EndIf

		If self.ignoreWhitespace Then
			Self._skipWhitespace()
		EndIf

		' Check for end of file.
		If Self._peekChar() = -1 Then
			self.CurrentToken = TOKEN_EOF
			Return 0
		EndIf

		' Get next character
		Local char:String = Chr(Self._readChar())

		If self.singleCharacterMode = False Then

			If Self.ignoreWhitespace = False And CharHelper.IsWhitespace(char) Then

				Local curString:String
				Local ch2:Int

				While (ch2 = Self._peekChar()) <> -1

					If Not(CharHelper.IsWhitespace(Chr(ch2))) Then
						Exit
					EndIf

					curString$	= curString$ + Chr(ch2)
					Self._readChar()

					self.CurrentToken	= TOKEN_WHITESPACE
					self.TokenText		= curString$

					Return 0

				Wend

			EndIf

			' Read numbers
			If CharHelper.IsDigit(char) Then

				self.CurrentToken	= TOKEN_NUMBER
				Local s$	= char

				While Self._peekChar() <> -1

					char = Chr(Self._peekChar())

					If CharHelper.IsDigit(char)
						s = s + Chr(Self._readChar())
					Else
						Exit
					EndIf

				Wend

				self.TokenText	= s
				Return 0

			EndIf

			' Read strings
			If char = "'" Then
				Self._ReadString()
				Return 0
			EndIf

			' Read keywords
			If char = "_" Or CharHelper.IsLetter(char) Then

				self.CurrentToken	= TOKEN_KEYWORD
				Local s:String = char

				While Self._peekChar() <> -1

					If (Chr(Self._peekChar()) = "_" Or Chr(Self._peekChar()) = "-" Or CharHelper.IsLetterOrDigit(Chr(Self._peekChar()))) Then
						s = s + Chr(Self._readChar())
					Else
						Exit
					EndIf

				Wend

				self.TokenText	= s
				If Self.TokenText.EndsWith("-") Then
					' Error
				EndIf
				Return 0

			EndIf

			' Move to next char?
		'	Self.ReadChar()

			' Read double character operators

			' Double colon - namespace seperator
			If (char = ":" And Self._peekChar() = Asc(":")) Then
				self.CurrentToken	= TOKEN_DOUBLE_COLON
				self.TokenText		= "::"
				Self._readChar()
				Return 0
			EndIf

			' Not equal
			If char = "!" And Self._peekChar() = Asc("=") Then
				self.CurrentToken	= TOKEN_NOT_EQUAL
				self.TokenText		= "!="
				Self._readChar()
				Return 0
			EndIf

			' Not equal (alternative)
			If char = "<" And Self._peekChar() = Asc(">") Then
				self.CurrentToken	= TOKEN_NOT_EQUAL
				self.TokenText		= "<>"
				Self._readChar()
				Return 0
			EndIf

			' Equal (C++ style)
			If char = "=" And Self._peekChar() = Asc("=") Then
				self.CurrentToken	= TOKEN_EQUAL
				self.TokenText		= "=="
				Self._readChar()
				Return 0
			EndIf

			' Less than equal (<=)
			If char = "<" And Self._peekChar() = Asc("=") Then
				self.CurrentToken	= TOKEN_LE
				self.TokenText		= "<="
				Self._readChar()
				Return 0
			EndIf

			' Greater than equal (<=)
			If char = ">" And Self._peekChar() = Asc("=") Then
				self.CurrentToken	= TOKEN_GE
				self.TokenText		= ">="
				Self._readChar()
				Return 0
			EndIf

		Else

			Self._readChar()

		EndIf

		self.TokenText		= char
		self.CurrentToken	= TOKEN_PUNCTUATION

		' Convert token types
		If Asc(char) >= 32 And Asc(char) <= 128 Then
			Self.CurrentToken	= ExpressionTokeniser.CharToToken(char)
		EndIf


	End Method

	''' <summary>Checks if the current token is a reserved keyword.</summary>
	''' <param name="word">The word to check against.</param>
	''' <returns>True if a keyword, false if not.</returns>
	Method isKeyword:Int(word:String)
		Return (self.CurrentToken = TOKEN_KEYWORD) And (self.TokenText = word)
	End Method

	Method isRelationalOperator:Byte()

		Local result:Byte = False

		' TODO: Not the prettiest. Tidy it up.
		Select self.currentToken
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
	Function CharToToken:Int(charValue:String)

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

	Method _readString:String()

		Local s$	= ""
		Local i%	= 0
		Local char$	= Chr(Self._peekChar())

		self.CurrentToken	= TOKEN_STRING

		While Self._peekChar() <> -1
			char = Chr(Self._peekChar())

			If char = "'" Then
				' Skip past the end of the string
				Self._readChar()
				Exit
			Else
				s = s + Chr(Self._readChar())
			EndIf

		Wend

		self.TokenText	= s

		Return s

	End Method

	''' <summary>Moves to the next character in the expression and returns its ascii value.</summary>
	Method _readChar:Int()

		Local charValue:Int = Self._peekChar()

		Self.CurrentPosition:+ 1

		Return charValue
	End Method

	Method _peekChar%()

		Local charValue% = -1

		If Self.CurrentPosition < Len(Self._expressionText) Then
			charValue	= Asc(Mid(self._expressionText, self.CurrentPosition + 1, 1))
		EndIf

		Return charValue

	End Method

	''' <summary>Reads all whitespace characters until the next non-whitespace character.</summary>
	Method _skipWhitespace()

		While (Self._peekChar()) <> -1
			If CharHelper.IsWhitespace(Chr(Self._peekChar())) = False Then Return
			Self._readChar()
		Wend

	End Method


	' ------------------------------------------------------------
	' -- Creation and Destruction
	' ------------------------------------------------------------

	Function Create:ExpressionTokeniser(expression$)

		Local this:ExpressionTokeniser = New ExpressionTokeniser

		' Initialise
		this._expressionText     = expression
		this.currentPosition     = 0
		this.currentToken        = TOKEN_BOF

		this.ignoreWhitespace    = True
		this.singleCharacterMode = False

		' Start tokenising
		this.getNextToken()

		Return this

	End Function

End Type
