' ------------------------------------------------------------------------------
' -- sodaware.blitzmax_array
' --
' -- Functions for working with arrays and linked lists.
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


SuperStrict

Module sodaware.blitzmax_array

Import brl.linkedlist

' ------------------------------------------------------------
' -- Array Functions
' ------------------------------------------------------------

''' <summary>
''' Remove the first element from an array and return it. This
''' will modify the contents of the passed in array.
''' </summary>
''' <param name="inputArray">The array to operate on.</param>
''' <return>The first element of the array.</return>
Function array_pull:Object(inputArray:Object[] Var)

	' Return null if the array is empty.
	If inputArray.Length = 0 Then Return Null

	' Get the first element so it can be returned.
	Local element:Object = inputArray[0]

	' Create a replacement array with the first element missing
	Local copy:Object[inputArray.Length - 1]
	For Local i:Int = 0 To inputArray.Length - 2
		copy[i] = inputArray[i + 1]
	Next
	inputArray = copy

	Return element

End Function

''' <summary>
''' Remove the last element from an array and return it. This
''' will modify the contents of the passed in array.
''' </summary>
''' <param name="inputArray">The array to operate on.</param>
''' <return>The last element of the array.</return>
Function array_pop:Object(inputArray:Object[] Var)

	' Return null if the array is empty or invalid.
	If inputArray.Length = 0 Then Return Null

	' Get the last element so it can be returned.
	Local element:Object = inputArray[inputArray.Length - 1]

	' Create a replacement array with the last element missing
	Local copy:Object[inputArray.Length - 1]
	For Local i:Int = 0 To inputArray.Length - 2
		copy[i] = inputArray[i]
	Next
	inputArray = copy

	Return element

End Function

''' <summary>Merge two arrays together into a new array.</summary>
''' <param name="arr1">The first array to merge.</param>
''' <param name="arr2">The second array to merge.</param>
''' <return>An array of containing all elements from both arrays.</return>
Function array_merge:Object[](arr1:Object[], arr2:Object[])

	' If one array is empty, no need to merge.
	If arr1.Length = 0 Then Return arr2
	If arr2.Length = 0 Then Return arr1

	' Create the new array.
	Local result:Object[arr1.Length + arr2.Length]
	Local i:Int

	For i = 0 To arr1.Length - 1
		result[i] = arr1[i]
	Next

	For i = 0 To arr2.Length - 1
		result[i + arr1.Length] = arr2[i]
	Next

	Return result

End Function

''' <summary>Add an element to the end of an array.</summary>
''' <param name="arr">The array to modify.</param>
''' <param name="obj">The element to add.</param>
''' <return>A new array containing all elements of `arr` with `obj` added to the end.</return>
Function array_append:Object[](arr:Object[], obj:Object)
	Local result:Object[arr.Length + 1]
	For Local i:Int = 0 To arr.Length - 1
		result[i] = arr[i]
	Next
	result[arr.Length] = obj
	Return result
End Function

''' <summary>Filter the contents of an array using a callback function.</summary>
''' <param name="inputArray">The array to filter.</param>
''' <param name="fn">Callback function that should take a single element. If the element can be included in the result, the function should return true.</param>
''' <return>A new array containing filtered elements from inputArray</return>
Function array_filter:Object[](inputArray:Object[], fn:Byte(o:Object))
	Local l:TList = New TList
	For Local obj:Object = EachIn inputArray
		If fn(obj) = True Then l.AddLast(obj)
	Next
	Return l.ToArray()
End Function

''' <summary>Check if an array contains a specific value. Will be slow for large arrays.</summary>
''' <param name="arr">The array to scan.</param>
''' <param name="obj">The object to search for.</param>
''' <return>True if obj was found, false if not.</return>
Function array_contains:Int(arr:Object[], obj:Object)
	For Local arrayObject:Object = EachIn arr
		If arrayObject = obj Then Return True
	Next
	Return False
End Function


' ------------------------------------------------------------
' -- Linked List Functions
' ------------------------------------------------------------

''' <summary>Filter the contents of a linked list using a callback function.</summary>
''' <param name="inputList">The list to filter.</param>
''' <param name="fn">
''' Callback function that takes a single element from the list as an argument. If
''' the element can be included in the result, the function must return true.
''' </param>
''' <return>A new TList containing filtered elements from inputList.</return>
Function tlist_filter:TList(inputList:TList, fn:Byte(o:Object))
	Return tlist_remove_if_not(inputList, fn)
End Function

''' <summary>Remove elements from a linked list if they pass the test in fn.</summary>
''' <param name="inputList">The list to filter.</param>
''' <param name="fn">Callback function that should take a single element.</param>
''' <return>A new TList containing filtered elements from inputList.</return>
Function tlist_remove_if:TList(inputList:TList, fn:Byte(o:Object))

	Local filteredList:TList = New TList

	For Local obj:Object = EachIn inputList
		If fn(obj) = False Then filteredList.AddLast(obj)
	Next

	Return filteredList

End Function

''' <summary>Remove elements from a linked list if they do not pass the test in fn.</summary>
''' <param name="inputList">The list to filter.</param>
''' <param name="fn">Callback function that should take a single element.</param>
''' <return>A new TList containing filtered elements from inputList.</return>
Function tlist_remove_if_not:TList(inputList:TList, fn:Byte(o:Object))

	Local filteredList:TList = New TList

	For Local obj:Object = EachIn inputList
		If fn(obj) = True Then filteredList.AddLast(obj)
	Next

	Return filteredList

End Function
