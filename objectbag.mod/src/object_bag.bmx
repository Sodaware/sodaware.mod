﻿' ------------------------------------------------------------------------------
' -- sodaware.objectbag -- src/object_bag.bmx
' --
' -- A "bag" is a collection of items that do not need to be in a particular
' -- order but need to be accessed quickly. It's slow to search for items, but
' -- fast to retrieve them by index (much like an array).
' --
' -- In most places a TList can be replaced with an ObjectBag with a few minor
' -- changes. ObjectBags also support EachIn operations.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict


''' <summary>
''' A "bag" is a collection of items that do not need to be in a particular
''' order but need to be accessed quickly. It's slow to search for items, but
''' fast to retrieve them by index (much like an array).
'''
''' In most places a TList can be replaced with an ObjectBag with a few minor
''' changes. ObjectBags also support EachIn operations.
''' </summary>
Type ObjectBag

	Const SORT_ASC:Int      = 1
	Const SORT_DESC:Int     = -1

	Field _size:Int                 '''< Number of items in the bag
	Field _objects:Object[]         '''< Bag contents


	' ------------------------------------------------------------
	' -- Retrieving bag information
	' ------------------------------------------------------------

	''' <summary>Get the number of items in the bag.</summary>
	''' <return>The number of items in the bag.</return>
	Method getSize:Int()
		Return Self._size
	End Method

	''' <summary>Get the capacity of the bag.</summary>
	''' <return>Bag capacity</return>
	Method getCapacity:Int()
		Return Self._objects.Length
	End Method

	''' <summary>Check if bag is empty.</summary>
	''' <return>True if empty, false if not.</return>
	Method isEmpty:Short()
		Return (Self._size = 0)
	End Method

	''' <summary>Check if a bag contains an object.</summary>
	''' <param name="obj">The object to search for.</param>
	''' <return>True if bag contains the object, false if not.</return>
	Method contains:Int(obj:Object)
		Return (Self.findObject(obj) <> -1)
	End Method

	''' <summary>Check if a bag contains an object, and returns its location if found.</summary>
	''' <param name="obj">The object to search for.</param>
	''' <return>Object offset if found, or -1 if not found.</return>
	Method findObject:Int(obj:Object)

		For Local pos:Int = 0 To Self._size - 1
			If Self._objects[pos] = obj Then Return pos
		Next

		Return -1

	End Method


	' ------------------------------------------------------------
	' -- Retrieving items
	' ------------------------------------------------------------

	''' <summary>Retrieve an object at a specific location.</summary>
	''' <param name="index">Offset to retrieve from.</param>
	''' <return>Object at this offset, or null if not found.</return>
	Method get:Object(index:Int)
		If index < 0 Or index >= Self._size Then Return Null
		Return Self._objects[index]
	End Method


	' ------------------------------------------------------------
	' -- Adding items
	' ------------------------------------------------------------

	''' <summary>
	''' Add a new object to the bag. Will expand the capacity of the
	''' bag if it is not big enough.
	''' </summary>
	''' <param name="obj">The object to add to the bag.</param>
	Method add(obj:Object)

		' Grow the bag if required
		If Self._size = Self._objects.Length Then Self._grow()

		' Add the data + move to the next position
		Self._objects[Self._size] = obj
		Self._size:+ 1

	End Method

	''' <summary>Add the contents of another ObjectBag to this bag.</summary>
	''' <param name="bag">The bag to add.</param>
	Method addCollection(bag:ObjectBag)

		If bag = Null Then Return

		' Add all items
		For Local pos:Int = 0 To bag.getSize() - 1
			Self.add(bag.get(pos))
		Next

	End Method

	''' <summary>Add the contents of an array to this bag.</summary>
	''' <param name="objects">The array to add.</param>
	Method addArray(objects:Object[])

		If objects = Null Then Return

		For Local obj:Object = EachIn objects
			Self.add(obj)
		Next

	End Method

	''' <summary>
	''' Set an object at a specific index. Will expand the bag if
	''' the index is greater than the current bag size.
	''' </summary>
	''' <param name="index">The index to set at.</param>
	''' <param name="obj">The object value.</param>
	Method set(index:Int, obj:Object)

		' Check bounds
		If index < 0 Then Throw "Cannot set element at index < 0"

		' Resize bag if required
		If index >= Self._objects.Length Then

			Self._grow(1 + (index * 2))
			Self._size = index + 1

		ElseIf index >= Self._size

			Self._size = index + 1

		End If

		Self._objects[index] = obj

	End Method


	' ------------------------------------------------------------
	' -- Removing items
	' ------------------------------------------------------------

	''' <summary>Remove an item from the bag and return it.</summary>
	''' <param name="index">The index to remove from.</param>
	''' <return>The object removed, or null if out of range.</return>
	Method remove:Object(index:Int)

		' Check bounds
		If index < 0 Or index >= Self._size Then Return Null

		' Get object
		Local obj:Object = Self._objects[index]

		' Replace object with end of list and then remove last item
		Self._objects[index] = Self._objects[Self._size - 1]
		Self._objects[Self._size - 1] = Null
		Self._size:- 1

		' Done
		Return obj

	End Method

	''' <summary>Remove the last item from the bag and return it.</summary>
	''' <return>Last item in bag, or null if bag is empty.</return>
	Method removeLast:Object()

		' Check list is not empty.
		If Self._size = 0 Then Return Null

		' Get object at end
		Local obj:Object = Self._objects[Self._size - 1]

		' Remove final object + resize list
		Self._objects[Self._size - 1] = Null
		Self._size:- 1

		' Done
		Return obj

	End Method

	''' <summary>Remove the first occurance of an object instance.</summary>
	''' <param name="obj">The object instance to remove.</param>
	''' <return>True if removed, false if not.</return>
	Method removeObject:Short(obj:Object)
		Return (Self.remove(Self.findObject(obj)) <> Null)
	End Method

	''' <summary>Remove all items from this bag that are present in another bag.</summary>
	''' <param name="bag">The bag containing items to remove.</param>
	''' <return>True if items removed, false if not.</return>
	Method removeCollection:Int(bag:ObjectBag)

		Local startSize:Int = Self._size

		For Local pos:Int = 0 To bag.getSize() - 1
			Self.removeObject(bag.get(pos))
		Next

		Return startSize <> Self._size

	End Method

	''' <summary>Clear the contents of the bag.</summary>
	Method clear()

		For Local pos:Int = 0 To Self._size - 1
			Self._objects[pos] = Null
		Next
		Self._size = 0

	End Method


	' ------------------------------------------------------------
	' -- Sorting
	' ------------------------------------------------------------

	''' <summary>Sort the contents of the bag.</summary>
	''' <param name="sortOrder">The order to use (either SORT_ASC or SORT_DESC). Default is SORT_ASC.</param>
	''' <param name="compareFunction">The function used to compare the two objects.</param>
	Method sort(sortOrder:Int = SORT_ASC, compareFunction:Int(obj1:Object, obj2:Object) = CompareBagObjects)

		' Check if bag needs to be sorted
		If Self.getSize() <= 1 Then Return

		Local isSwapped:Byte	= False
		Local pos:Int			= 0
		Local startPos:Int		= -1
		Local endPos:Int		= Self.getSize() - 2

		Repeat

			' Move start position + reset swap flag
			startPos:+ 1
			isSwapped = False

			' Forward search
			For pos = startPos To endPos
				If compareFunction(Self.get(pos), Self.get(pos + 1)) = sortOrder Then
					Self._swap(pos, pos + 1)
					isSwapped = True
				EndIf
			Next

			' If no swaps, array is sorted
			If Not(isSwapped) Then Exit

			' Backward search
			isSwapped = False
			endPos:- 1
			For pos = endPos To startPos Step -1
				If compareFunction(Self.get(pos), Self.get(pos + 1)) = sortOrder Then
					Self._swap(pos, pos + 1)
					isSwapped = True
				EndIf
			Next

		Until isSwapped = False

	End Method

	''' <summary>Swaps two elements.</summary>
	''' <param name="targetPos">The element to move.</param>
	''' <param name="destinationPos">The element to move to.</param>
	Method _swap(targetPos:Int, destinationPos:Int)

		Local temp:Object = Self.get(destinationPos)
		Self.set(destinationPos, Self.get(targetPos))
		Self.set(targetPos, temp)

	End Method


	' ------------------------------------------------------------
	' -- Internal helpers
	' ------------------------------------------------------------

	''' <summary>
	''' Increase the capacity of the bag. The new capacity can either be specified
	''' with the newCapacity parameter, otherwise it will automatically expand to
	''' 1.5 times it's current size.
	''' </summary>
	''' <param name="newCapacity">Optional new capacity.</param>
	Method _grow(newCapacity:Int = -1)

		' Use default new size if none set
		If newCapacity < 0 Then newCapacity = ((Self._objects.Length * 3) / 2) + 1

		' Resize the internal array.
		Self._objects = Self._objects[..newCapacity]

	End Method


	' ------------------------------------------------------------
	' -- ForEach support
	' ------------------------------------------------------------

	Method ObjectEnumerator:ObjectBagEnum()
		Return ObjectBagEnum.Create(Self)
	End Method


	' ------------------------------------------------------------
	' -- Construction / Destruction
	' ------------------------------------------------------------

	''' <summary>Create a new ObjectBag with an initial capacity.</summary>
	''' <param name="capacity">Size of the bag to create.</param>
	''' <return>An ObjectBag instance.</return>
	Function Create:ObjectBag(capacity:Int = 0)

		Local this:ObjectBag = New ObjectBag
		this._objects = New Object[capacity]
		Return this

	End Function

End Type


' ------------------------------------------------------------
' -- EachIn support
' ------------------------------------------------------------

Type ObjectBagEnum

	Field _bag:ObjectBag
	Field _pos:Int = 0

	Function Create:ObjectBagEnum(bag:ObjectBag)
		Local this:ObjectBagEnum = New ObjectBagEnum
		this._bag = bag
		Return this
	End Function

	Method HasNext:Int()
		Return Self._pos < Self._bag.getSize()
	End Method

	Method NextObject:Object()
		Local obj:Object = Self._bag.get(Self._pos)
		Self._pos:+ 1
		Return obj
	End Method

End Type


' ------------------------------------------------------------
' -- Search support
' ------------------------------------------------------------

Function CompareBagObjects:Int(obj1:Object, obj2:Object)
	Return obj1.Compare(obj2)
End Function
