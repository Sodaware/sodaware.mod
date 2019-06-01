' ------------------------------------------------------------------------------
' -- src/command_line_options.bmx
' --
' -- Base type that application options must extend.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


' TODO: Make it work for space seperators
' TODO: MAke it work for properties (e.g. if field is array, it may appear multiple times)
' TODO: If no LongName found, use the field name in lowercase

SuperStrict

Import brl.linkedlist
Import brl.map
Import brl.reflection
Import brl.retro

Include "command_line_helpers.bmx"

''' <summary>
''' Base class for a command line options helper. Create your options as a subclass
''' of this, and call the "Init" option with the application args.
''' </summary>
Type CommandLineOptions

	' -- Internal fields
	Field _isInitialised:Byte    = False
	Field _optionLookup:TMap     = New TMap     '''< Cache of field Name -> optionattribute.

	' -- Public stuff
	Field Arguments:TList        = New TList    '''< List of arguments.

	' -- Parser options
	Field AllowForwardSlash:Byte = True


	' ------------------------------------------------------------
	' -- Creation and destruction
	' ------------------------------------------------------------


	''' <summary>Initialises the command line.</summary>
	''' <param name="args">String array of arguments to parse.</param>
	''' <remarks>Normally AppArgs will be passed to this method.</remarks>
	Method init(args:String[])

		' Clear arguments/options if previously initialized.
		If Self._isInitialised Then
			Self.Arguments.Clear()
			Self._optionLookup.Clear()
		EndIf

		' TODO: Create our cache of options ?


		' Iterate through the command line arguments
		Local count:Int		= 0
		Local optionPos:Int	= 1

		While optionPos < args.Length

			' If currentArg _could_ be an option (-, -- Or /)
			Local namePosition:Int	= CommandLineHelpers.GetOptionNamePosition(args[optionPos], Self.AllowForwardSlash)

			' If found, set the value
			If namePosition > 0 Then

				' Split into option name and value
				Local optionName:String		= CommandLineHelpers.GetOptionName(Mid(args[optionPos], nameposition + 1))
				Local optionValue:String	= CommandLineHelpers.GetOptionValue(Mid(args[optionPos], nameposition + 1))

				' If no value set, it's a switch so should be set to true
				If optionValue = Null And optionName <> "" Then optionValue = 1

				' Try to set the value
				If Self._setOption(optionName, optionValue) = False Then
					' TODO: Don't want this - just flag the error instead
					Throw "Attempted to set option ~q" + optionName + "~q, but failed."
				Else
					count:+1
				EndIf
			Else
				' Not found, so add to list of arguments
				Self.Arguments.AddLast(args[optionPos])
			End If

			' Move to next option
			optionPos:+ 1
		Wend

		Self._isInitialised	= True

	End Method


	' ------------------------------------------------------------
	' -- Output methods
	' ------------------------------------------------------------

	''' <summary>Creates a formatted help string for the command line options.</summary>
	''' <remarks>Will exclude any field that does not have a "Description" meta field.</remarks>
	''' <param name="columnWidth">The number of characters to wrap at.</param>
	''' <param name="useColours">If true, will add coluor codes for use with console_color module</param>
	''' <returns>The formatted string.</returns>
	Method createHelp:String(columnWidth:Int = 80, useColours:Byte = False)

		' TODO: Find the longest longname, + 2 for indent
		' TODO: Wrap text to specified distance
		' TODO: Add colours

		' Find the longest name (for padding).
		Local longestName:String = Self._findLongestName()
		Local helpText:String    = ""
		Local wrapWidth:Int		 = 12 + longestName.Length

		' Display each field.
		Local optionsObject:TTypeId = TTypeId.ForObject(Self)
		For Local currentOption:TField = EachIn optionsObject.EnumFields()

			Local optionMeta:Tmap = CommandLineHelpers.ParseMetaString(currentOption.MetaData())

			' Skip fields with no description.
			If optionMeta.ValueForKey("Description") = Null Then Continue

			' Skip fields that have `NoHelp` set
			If optionMeta.ValueForKey("NoHelp") <> Null Then Continue

			' Add fields
'			If useColours Then helpText = helpText + "%Y"
			helpText = helpText + "  -" + String(optionMeta.ValueForKey("ShortName")) + "  --" + LSet(String(optionMeta.ValueForKey("LongName")), longestName.Length +5)
'			If useColours Then helpText = helpText + "%n"

			' Add description
			helpText = helpText + CommandLineHelpers.WrapText(String(optionMeta.ValueForKey("Description")), wrapWidth, columnWidth) + "~n"

		Next

		Return helpText

	End Method


	' ------------------------------------------------------------
	' -- Access Methods
	' ------------------------------------------------------------

	''' <summary>Returns true if command line is initialized, false if not.</summary>
	''' <returns>True if initialised, false if not.</returns>
	Method isInitialized:Byte()
		Return Self._isInitialised
	End Method

	''' <summary>Does this commandline object have any arguments.</summary>
	''' <returns>True if has arguments, false if not.</returns>
	Method hasArguments:Byte()
		Return (Self.Arguments.Count() > 0)
	End Method

	''' <summary>Gets the number of arguments.</summary>
	''' <returns>Number of arguments.</returns>
	Method countArguments:Int()
		Return Self.Arguments.Count()
	End Method

	''' <summary>Gets an argument from the command line by its position.</summary>
	''' <param name="argPos">The offset of the argument to get.</param>
	''' <returns>The argument found, or null if out of range.</returns>
	Method getArgument:String(argPos:Int)
		If argPos < 0 Or argPos >= Self.Arguments.Count() Then Return Null
		Return String(Self.Arguments.ValueAtIndex(argPos))
	End Method


	' ------------------------------------------------------------
	' -- Internal methods
	' ------------------------------------------------------------

	''' <summary>Sets the value of an option.</summary>
	''' <param name="optionName">The name of the option to set.</param>
	''' <param name="optionValue">The value of the option to set.</param>
	''' <returns>True if option set correctly, false if not.</returns>
	Method _setOption:Byte(optionName:String, optionValue:Object)

		' Check if option is an array
		If optionName.Contains(":") Then Return Self._setOptionMap(optionName, optionValue)

		Local option:TField	= Self._findOptionField(optionName)
		If option = Null Then Return False

		option.set(Self, optionValue)
		Return True

	End Method

	''' <summary>Sets an option that is part of a TMap.</summary>
	''' <param name="optionName">The name of the option to set (option:key).</param>
	''' <param name="optionValue">The value of the option to set.</param>
	''' <returns>True if option set correctly, false if not.</returns>
	Method _setOptionMap:Byte(optionName:String, optionValue:Object)

		Local optionFamily:String = Left(optionName, optionName.Find(":"))
		Local optionKey:String    = Right(optionName, optionName.Length - optionName.Find(":") - 1)

		Local option:TField	= Self._findOptionField(optionFamily)
		If option = Null Then Return False

		Local map:TMAP	= tmap(option.Get(Self))
		If map = Null Then Return Null

		map.Insert(optionKey, optionValue)
		Return True

	End Method

	''' <summary>Gets a BlitzMax field object by searching for names and LongName/ShortName metadata.</summary>
	''' <param name="optionName">The name of the option to find.</param>
	''' <returns>Reflection field, or null if not found.</returns>
	Method _findOptionField:TField(optionName:String)

		Local opt:TTypeId = TTypeId.ForObject(Self)

		For Local fld:TField = EachIn opt.enumfields()

			' Check if field name is equal to option name
			If fld.Name().ToLower() = optionName.ToLower() Then
				Return fld
			Else
				' Not found - was it in the meta data?
				Local options:TMap	= CommandLineHelpers.ParseMetaString(fld.MetaData())

				' Long option
				If Trim(optionName.ToLower()) = Trim(String(options.ValueForKey("LongName")).ToLower()) Then
					Return fld
				End If

				' Short options
				If Trim(optionName) = String(options.ValueForKey("ShortName")) Then
					Return fld
				End If
			End If

		Next

		Return Null

	End Method

	''' <summary>Finds the longest LongName meta field (used for formatting).</summary>
	''' <returns>The longest LongName meta field.</returns>
	Method _findLongestName:String()

		Local longestValue:String = ""
		Local option:TTypeId = TTypeId.ForObject(Self)

		For Local fld:TField = EachIn option.enumfields()

			Local optionMeta:Tmap = CommandLineHelpers.ParseMetaString(fld.MetaData())

			If longestValue.Length < String(optionMeta.ValueForKey("LongName")).Length Then
				If optionMeta.ValueForKey("Description") <> Null Then
					longestValue = String(optionMeta.ValueForKey("LongName"))
				EndIf
			EndIf

		Next

		Return longestValue

	End Method

End Type
