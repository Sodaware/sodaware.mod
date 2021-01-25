' ------------------------------------------------------------------------------
' -- src/string_list.bmx
' --
' -- StringList object definition.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Private

Function CompareStringListObjects:Int( o1:String,o2:String )
	Return o1.Compare( o2 )
End Function

Type StringList_Link

	Field _value:String
	Field _succ:StringList_Link
	Field _pred:StringList_Link
	
	Method value:String()
		Return self._value
	End Method

	Rem
	bbdoc: Removes the link from the List.
	End Rem
	Method remove()
		self._value      = Null
		self._succ._pred = self._pred
		self._pred._succ = self._succ

		self._pred = null
		self._succ = null
	End Method

End Type

Public 

Type StringListIterator

	Field _link:StringList_Link

	Method hasNext:Int()
		debuglog "hasNext"
		debuglog "succ: " + self._link._succ._value 
		debuglog "pred: " + self._link._pred._value 
		Return self._link._succ._value <> ""
	End Method

	Method nextObject:Object()
		Local value:String=_link._value
		self._link = self._link._succ
		Return value
	End Method

End Type

Type StringList

	Field _head:StringList_Link
	field _cachedSize:Int
	
	Method New()
		_head=New StringList_Link
		_head._succ  = _head
		_head._pred  = _head
		_head._value = null
	End Method
	
?Not Threaded
	Method Delete()
		Clear
		_head._value=Null
		_head._succ=Null
		_head._pred=Null
	End Method
?
	
	' ----------------------------------------------------------------------
	' -- List Information
	' ----------------------------------------------------------------------

	''' <summary>Check if list is empty.</summary>
	''' <returns>True if list is empty, else false</returns>
	Method isEmpty:Int()
		Return ( self._head._succ = self._head )
	End Method
	
	Rem
	bbdoc: Check if list contains a value
	returns: True if list contains @value, else false
	end rem
	Method contains:Int( value:Object )
		Local link:StringList_Link=_head._succ
		While link<>_head
			If link._value.Compare( value )=0 Return True
			link=link._succ
		Wend
		Return False
	End Method
	

	' ----------------------------------------------------------------------
	' -- Adding and Removing items
	' ----------------------------------------------------------------------

	''' <summary>Clear all items from the list.</summary>
	Method clear()
		While self._head._succ <> self._head
			self._head._succ.remove()
		Wend
		self._cachedSize = 0
	End Method


	Rem
	bbdoc: Add an object to the start of the list
	returns: A link object
	End Rem
	Method addFirst:StringList_Link( value:String )
		Return self.insertAfterLink( value, self._head )
	End Method

	Rem
	bbdoc: Add an object to the end of the list
	returns: A link object
	End Rem
	Method addLast:StringList_Link( value:String )
		Return self.insertBeforeLink( value, self._head )
	End Method

	Method add:StringList_Link(value:String)
		Return self.insertBeforeLink(value, self._head)
	End Method
	
	''' <summary>Returns the first object in the list.</summary>
	''' <returns>Null if the list is empty.</returns>
	Method first:String()
		If self.isEmpty() then Return null
		Return self._head._succ._value
	End Method

	''' <summary>Returns the last object in the list.</summary>
	''' <returns>Returns Null if the list is empty.</returns>
	Method last:String()
		If self.isEmpty() then Return null
		Return self._head._pred._value
	End Method

	Rem
	bbdoc: Removes and returns the first object in the list.
	about: Returns Null if the list is empty.
	End Rem
	Method removeFirst:String()
		If self.isEmpty() then Return null
		Local value:String=_head._succ._value
		_head._succ.remove()
		self._cachedSize :- 1
		Return value
	End Method

	Rem
	bbdoc: Removes and returns the last object in the list.
	about: Returns Null if the list is empty.
	End Rem
	Method removeLast:String()
		If IsEmpty() Return null
		Local value:String = self._head._pred._value
		_head._pred.remove
		self._cachedSize :- 1

		Return value
	End Method

	Rem
	bbdoc: Returns the first link the list or null if the list is empty.
	End Rem
	Method FirsStringList_Link:StringList_Link()
		If _head._succ<>_head Return _head._succ
	End Method

	Rem
	bbdoc: Returns the last link the list or null if the list is empty.
	End Rem
	Method LasStringList_Link:StringList_Link()
		If _head._pred<>_head Return _head._pred
	End Method

	Rem
	bbdoc: Inserts an object before the specified list link.
	End Rem
	Method insertBeforeLink:StringList_Link( value:String, succ:StringList_Link )
		
		Local link:StringList_Link = New StringList_Link
		link._value = value
		link._succ  = succ
		link._pred  = succ._pred
		link._pred._succ = link
		succ._pred  = link

		self._cachedSize :+ 1

		Return link
	End Method

	Rem
	bbdoc: Inserts an object after the specified list link.
	End Rem
	Method insertAfterLink:StringList_Link(value:String, pred:StringList_Link)
		
		Local link:StringList_Link = New StringList_Link
		link._value      = value
		link._pred       = pred
		link._succ       = pred._succ
		link._succ._pred = link
		pred._succ       = link

		self._cachedSize :+ 1

		Return link
	End Method

	Rem
	bbdoc: Returns the first link in the list with the given value, or null if none found.
	End Rem
	Method FindLink:StringList_Link( value:Object )
		Local link:StringList_Link=_head._succ
		While link<>_head
			If link._value.Compare( value )=0 Return link
			link=link._succ
		Wend
	End Method

	Rem
	bbdoc: Returns the value of the link at the given index.
	about: Throws an exception if the index is out of range (must be 0..list.Count()-1 inclusive).
	End Rem
	Method ValueAtIndex:Object( index:Int )
		Assert index>=0 Else "Object index must be positive"
		Local link:StringList_Link=_head._succ
		While link<>_head
			If Not index Return link._value
			link=link._succ
			index:-1
		Wend
		RuntimeError "List index out of range"
	End Method

	''' <summary>Count the number of items in the list.</summary>
	Method count:Int()
		Return self._cachedSize
	End Method

	Rem
	bbdoc: Remove an object from a linked list
	about: Remove scans a list for the specified value and removes its link.
	End Rem
	Method Remove:Int( value:Object )
		Local link:StringList_Link=FindLink( value )
		If Not link Return False
		link.Remove
		self._cachedSize :- 1

		Return True
	End Method
	
	Rem
	bbdoc: Swap contents with the list specified.
	End Rem
	Method Swap( list:StringList )
		Local head:StringList_Link=_head
		_head=list._head
		list._head=head
	End Method
	
	Rem
	bbdoc: Creates an identical copy of the list.
	End Rem
	Method Copy:StringList()
		Local list:StringList=New StringList
		Local link:StringList_Link=_head._succ
		While link<>_head
			list.AddLast link._value
			link=link._succ
		Wend
		Return list
	End Method

	Rem
	bbdoc: Reverse the order of the list.
	End Rem
	Method Reverse()
		Local pred:StringList_Link=_head,succ:StringList_Link=pred._succ
		Repeat
			Local link:StringList_Link=succ._succ
			pred._pred=succ
			succ._succ=pred
			pred=succ
			succ=link
		Until pred=_head
	End Method
	
	Rem
	bbdoc: Creates a new list that is the reversed version of this list.
	End Rem
	Method Reversed:StringList()
		Local list:StringList=New StringList
		Local link:StringList_Link=_head._succ
		While link<>_head
			list.AddFirst link._value
			link=link._succ
		Wend
		Return list
	End Method

	Rem
	bbdoc: Sort a list in either ascending (default) or decending order.
	about: User types should implement a Compare method in order to be sorted.
	End Rem
	Method Sort(ascending:Int = True, compareFunc:Int(o1:String,o2:String) = CompareStringListObjects)
		Local ccsgn:Int=-1
		If ascending ccsgn=1
		
		Local insize:int=1
		Repeat
			Local merges:int
			Local tail:StringList_Link=_head
			Local p:StringList_Link=_head._succ

			While p<>_head
				merges:+1
				Local q:StringList_Link=p._succ,qsize:int=insize,psize:int=1
				
				While psize<insize And q<>_head
					psize:+1
					q=q._succ
				Wend

				Repeat
					Local t:StringList_Link
					If psize And qsize And q<>_head
						Local cc:Int=CompareFunc( p._value,q._value ) * ccsgn
						If cc<=0
							t=p
							p=p._succ
							psize:-1
						Else
							t=q
							q=q._succ
							qsize:-1
						EndIf
					Else If psize
						t=p
						p=p._succ
						psize:-1
					Else If qsize And q<>_head
						t=q
						q=q._succ
						qsize:-1
					Else
						Exit
					EndIf
					t._pred=tail
					tail._succ=t
					tail=t
				Forever
				p=q
			Wend
			tail._succ=_head
			_head._pred=tail

			If merges<=1 Return

			insize:*2
		Forever
	End Method
		
	Method ObjectEnumerator:StringListIterator()
		Local enumerator:StringListIterator = New StringListIterator
		enumerator._link = self._head

		Return enumerator
	End Method

	''' <summary>Convert a list to an array.</summary>
	''' <returns>An array of objects.</returns>
	Method toArray:String[]()
		' TODO: Remove the `toString` method
		Local result:String[self.count()]
		Local i:Int
		Local link:StringList_Link = self._head._succ
		While link <> self._head
			result[i] = link._value.toString()
			link = link._succ
			i :+ 1
		Wend
		Return result
	End Method

	''' <summary>Create a StringList from an array of strings.</summary>
	''' <returns>A new StringList.</returns>
	Function FromArray:StringList( arr:String[] )
		Local list:StringList = New StringList
		For Local i:Int = 0 Until arr.length
			list.addLast(arr[i])
		Next
		Return list
	End Function

End Type
