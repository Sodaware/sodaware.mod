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
		If self.currentToken = TOKEN_EOF Then
			Throw "End of file reached"
		EndIf

		' Skip whitespace characters if they're being ignored.
		If self.ignoreWhitespace Then
			Self._skipWhitespace()
		EndIf

		' Check for end of file.
		If Self._peekChar() = 0 Then
			self.CurrentToken = TOKEN_EOF
			Return 0
		EndIf

		' Get next character
		Local char:String = Chr(Self._readChar())

		' TODO: Is single character mode something anyone will actually use?
		If self.singleCharacterMode = False Then

			If Self.ignoreWhitespace = False And CharHelper.IsWhitespace(char) Then

				Local curString:String
				Local ch2:Byte

				While (ch2 = Self._peekChar()) <> 0

					If Not(CharHelper.IsWhitespace(Chr(ch2))) Then
						Exit
					EndIf

					curString:String = curString:String + Chr(ch2)
					Self._readChar()

					self.CurrentToken	= TOKEN_WHITESPACE
					self.TokenText		= curString:String

					Return 0

				Wend

			EndIf

			' Read numbers
			If CharHelper.IsDigit(char) Then

				Self.currentToken = TOKEN_NUMBER

				' Read the number.
				Local s:String = char

				While Self._peekChar() <> 0
					char = Chr(Self._peekChar())

					If CharHelper.IsDigit(char)
						s = s + Chr(Self._readChar())
					Else
						Exit
					EndIf
				Wend

				self.tokenText = s

				Return 0

			EndIf

			' Read strings
			If char = "'" Then
				Self._ReadString()
				Return 0
			EndIf

			' Read keywords
			If char = "_" Or CharHelper.IsLetter(char) Then

				self.currentToken = TOKEN_KEYWORD
				Local s:String = char

				While Self._peekChar() <> 0

					' TODO: This is ugly. Fix it.
					If (Chr(Self._peekChar()) = "_" Or Chr(Self._peekChar()) = "-" Or CharHelper.IsLetterOrDigit(Chr(Self._peekChar()))) Then
						s = s + Chr(Self._readChar())
					Else
						Exit
					EndIf

				Wend

				self.TokenText	= s
				Return 0

			EndIf

			' Read double character operators

			' Double colon - namespace seperator
			If (char = ":" And Self._peekChar() = ASC_COLON) Then
				self.currentToken	= TOKEN_DOUBLE_COLON
				self.tokenText		= "::"
				Self._readChar()
				Return 0
			EndIf

			' Not equal
			If char = "!" And Self._peekChar() = ASC_EQUALS Then
				self.currentToken	= TOKEN_NOT_EQUAL
				self.tokenText		= "!="
				Self._readChar()
				Return 0
			EndIf

			' Not equal (alternative)
			If char = "<" And Self._peekChar() = ASC_GREATER_THAN Then
				self.currentToken	= TOKEN_NOT_EQUAL
				self.tokenText		= "<>"
				Self._readChar()
				Return 0
			EndIf

			' Equal (C++ style)
			If char = "=" And Self._peekChar() = ASC_EQUALS Then
				self.currentToken	= TOKEN_EQUAL
				self.tokenText		= "=="
				Self._readChar()
				Return 0
			EndIf

			' Less than equal (<=)
			If char = "<" And Self._peekChar() = ASC_EQUALS Then
				self.currentToken	= TOKEN_LE
				self.tokenText		= "<="
				Self._readChar()
				Return 0
			EndIf

			' Greater than equal (>=)
			If char = ">" And Self._peekChar() = ASC_EQUALS Then
				self.currentToken	= TOKEN_GE
				self.tokenText		= ">="
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
			Self.CurrentToken = ExpressionTokeniser.CharToToken(char)
		EndIf


	End Method

	''' <summary>Checks if the current token is a reserved keyword.</summary>
	''' <param name="word">The word to check against.</param>
	''' <returns>True if a keyword, false if not.</returns>
	Method isKeyword:Int(word:String)
		Return (self.CurrentToken = TOKEN_KEYWORD And self.TokenText = word)
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
		Local s:String    = ""
		Local char:String = Chr(Self._peekChar())

		While Self._peekChar() <> 0
			char = Chr(Self._peekChar())

			If char = "'" Then
				' Skip past the end of the string
				Self._readChar()
				Exit
			Else
				s :+ Chr(Self._readChar())
			EndIf
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

	' TODO: Return 0 for end?
	Method _peekChar:Byte()
		If Self.CurrentPosition < Self._expressionText.Length Then
			Return Self._expressionText[Self.currentPosition]
		EndIf

		Return 0
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
		Self.singleCharacterMode = False

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
