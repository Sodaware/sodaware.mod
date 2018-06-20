' ------------------------------------------------------------------------------
' -- sodaware.console_progressbar
' --
' -- A very simple console-based progress bar.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2008-2018 Phil Newton
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


Module sodaware.Console_ProgressBar

SuperStrict

Import brl.retro

Import sodaware.console_basic
Import sodaware.console_color

Type Console_ProgressBar

	Field _template:String       '''< Progress bar template containing placeholders.
	Field _bar:String            '''< The bar gets filled with this
	Field _fill:String           '''< Empty space gets filled with this
	Field _barLength:Int         '''< The width of the bar
	Field _totalLength:Int       '''< The total width of the display
	Field _targetNumber:Float    '''< The position of the counter when the job is `done'
	Field _before:String         '''< Optional text to render before the bar.
	Field _after:String          '''< Optional text to render after the bar.


	' ------------------------------------------------------------
	' -- Configuration
	' ------------------------------------------------------------

	''' <summary>
	''' Set the template to use when rendering the bar. Supports the following
	''' placeholders:
	''' * %bar%     - Display the progress bar.
	''' * %percent% - Display the current completion percentage.
	''' </summary>
	''' <param name="template">The bar template.</param>
	''' <return>Self</return>
	Method setTemplate:Console_ProgressBar(template:String)
		Self._template = template
		Return Self
	End method

	''' <summary>Set the characters to use when displaying the bar.</summary>
	''' <param name="bar">Bar characters.</param>
	''' <return>Self</return>
	Method setBar:Console_ProgressBar(bar:String)
		Self._bar = bar
		Return Self
	End Method

	''' <summary>Set the characters to fill empty space on the bar.</summary>
	''' <param name="bar">Background fill characters.</param>
	''' <return>Self</return>
	Method setBackground:Console_ProgressBar(fill:String)
		Self._fill = fill
	End Method

	''' <summary>Set the length of the bar (in characters).</summary>
	''' <param name="length">Bar length in characters.</param>
	''' <return>Self</return>
	Method setBarLength:Console_ProgressBar(length:Int)
		Self._barLength = length
		Return Self
	End Method

	''' <summary>Set text to display before the main bar template.</summary>
	''' <param name="beforeText">Text to display before the full progress bar.</param>
	''' <return>Self</return>
	Method setBeforeText:Console_ProgressBar(beforeText:string)
		Self._before = beforeText
		Return Self
	End Method

	''' <summary>Set text to display after the main bar template.</summary>
	''' <param name="afterText">Text to display after the full progress bar.</param>
	''' <return>Self</return>
	Method setAfterText:Console_ProgressBar(afterText:string)
		Self._after = afterText
		Return Self
	End Method


	' ------------------------------------------------------------
	' -- Updating
	' ------------------------------------------------------------

	' TODO: Store time here, so it can be used to estimate time to completion.
	Method update(currentValue:Float)
		Self.display(currentValue)
	End Method


	' ------------------------------------------------------------
	' -- Display
	' ------------------------------------------------------------

	Method display(currentValue:Float)
		Local output:String = Self._template

		' Calculate bar length
		Local barLength:Int  = Self._barLength * currentValue
		Local barBody:String = Self._repeatString(Self._bar, barLength)
		Local barBg:String   = Self._repeatString(Self._fill, Self._barLength - barLength)

		' Calculate percentage.
		Local percentage:Float = currentValue * 100

		' Replace template placeholders
		output = Self._replaceToken(output, "bar", barBody + barBg)
		output = Self._replaceToken(output, "percent", Self.trimNumber(percentage, 1) + "%")

		ClearLine()
		WriteC(Self._before + output + Self._after)
	End Method


	' ------------------------------------------------------------
	' -- Internal Helpers
	' ------------------------------------------------------------

	Method _replaceToken:String(text:String, token:String, value:String)
		Return text.Replace("%" + token + "%", value)
	End Method

	Method _repeatString:String(content:String, length:Int)

		Local rString:String = ""
		For Local i:Int = 1 To length
			rString = rString + content
		Next

		Return rString

	End Method

	Method trimNumber:string(number:Float, precision:Byte = 1)
		Local value:String   = String(number)
		Local parts:String[] = value.split(".")

		If parts.length <> 2 Then Return value

		Local remainder:String = Left(parts[1], precision)

		If remainder.length < precision then
			remainder = LSet(remainder, precision - remainder.length)
			remainder = remainder.Replace(" ", "0")
		EndIf

		Return parts[0] + "." + remainder
	End Method


	' ------------------------------------------------------------
	' -- Construction
	' ------------------------------------------------------------

	''' <summary>Create and return a new progress bar.</summary>
	''' <param name="template">The bar template to use. See `setTemplate` for available tokens.</param>
	''' <param name="barFill">Characters to fill the bar with.</param>
	''' <param name="spaceFill">Characters to fill the background with.</param>
	''' <param name="barWidth">Width of the bar in characters.</param>
	''' <return>The created progress bar.</return>
	Function Create:Console_ProgressBar(template:String = "[%bar%] %percent%", barFill:String = "=", spaceFill:String = " ", barWidth:Int = 80)
		Local this:Console_ProgressBar = New Console_ProgressBar

		this.setTemplate(template)
		this.setBar(barFill)
		this.setBackground(spaceFill)
		this.setBarLength(barWidth)

		Return this
	End Function

End Type
