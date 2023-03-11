' ------------------------------------------------------------------------------
' -- src/string_table.bmx
' --
' -- StringTable object definition. Based on BlitzMax's built-in "TMap" type,
' -- but strongly-typed for strings.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

''' <summary>
''' Get and set string values. Works in a similar way to a TMap,
''' but is strongly typed for strings.
'''
''' Use `get` and `set` methods for fetching and setting data.
''' </summary>
Type StringTable
	Const RED:Byte   = 1
	Const BLACK:Byte = 2

	Field _root:StringTable_Node = nil
	Field _size:Int              = 0

?Not Threaded
	Method delete()
		self.clear()
	End Method
?

	' ------------------------------------------------------------
	' -- Creation
	' ------------------------------------------------------------

	Function Create:StringTable(keys:String[], values:String[] = Null)
		Local this:StringTable = New StringTable

		If keys.length > 0 And keys.length = values.length Then
			For Local i:Int = 0 To keys.length - 1
				this.set(keys[i], values[i])
			Next
		EndIf

		' Alternative syntax.
		If keys.length > 0 And values = Null Then
			For Local i:Int = 0 To keys.length - 1 Step 2
				this.set(keys[i], keys[i + 1])
			Next
		EndIf

		Return this
	End Function


	' ------------------------------------------------------------
	' -- Getting and Setting
	' ------------------------------------------------------------

	''' <summary>Get the value for key in the string table.</summary>
	''' <param name="key">The key to search for.</param>
	''' <return>The value found, or an empty string if not found.</return>
	Method get:String(key:String)
		Local node:StringTable_Node = Self._findNode(key)
		If node <> nil Then Return node._value
	End Method

	''' <summary>Set the value for key in the string table.</summary>
	''' <param name="key">The key to set.</param>
	''' <param name="value">The value to set.</param>
	''' <return>The stringtable object.</return>
	Method set:StringTable(key:String, value:String)
		Self.insert(key, value)

		Return Self
	End Method

	''' <summary>Remove an element from the string table by key.</summary>
	''' <return>True if removed, false if not.</return>
	Method remove:Byte(key:String)
		Local node:StringTable_Node = Self._findNode(key)
		If node = nil Then Return False

		' Node is found - remove it and reduce internal size cache.
		Self._removeNode(node)
		Self._size:- 1

		Return True
	End Method


	' ------------------------------------------------------------
	' -- Querying
	' ------------------------------------------------------------

	''' <summary>Get the size of the StringTable.</summary>
	Method size:Int()
		Return Self._size
	End Method

	Method isEmpty:Byte()
		Return (Self._root = nil)
	End Method

	Method contains:Byte(key:String)
		Return (Self._findNode(key) <> nil)
	End Method


	' ------------------------------------------------------------
	' -- TMAp compat
	' ------------------------------------------------------------

	Method valueForKey:String(key:String)
		Local node:StringTable_Node = Self._findNode(key)
		If node <> nil Then Return node._value
	End Method


	' ------------------------------------------------------------
	' -- Internal adding and removing
	' ------------------------------------------------------------

	Method insert(key:String, value:String)
		Assert key Else "Can't insert empty key into StringTable"

		Local node:StringTable_Node   = _root
		Local parent:StringTable_Node = nil
		Local cmp:Int

		While node <> nil
			parent = node
			cmp = key.Compare(node._key)
			If cmp > 0 Then
				node = node._right
			ElseIf cmp < 0 Then
				node = node._left
			Else
				' Already exists - set the value and leave.
				node._value = value
				Return
			EndIf
		Wend

		' Update internal size cache.
		Self._size:+ 1

		' Initialize a new node and set values.
		node         = New StringTable_Node
		node._key    = key
		node._value  = value
		node._color  = RED
		node._parent = parent

		If parent = nil Then
			self._root = node
			Return
		EndIf

		If cmp > 0 Then
			parent._right = node
		Else
			parent._left = node
		EndIf

		' Update internals.
		Self._insertFixup(node)

	End Method

	Method clear()
		If Self.isEmpty() Then Return

		self._root.clear()
		self._root = nil
	End Method

	' TODO: Legacy code.
	Method keys:StringTable_MapEnumerator()
		Local nodeenum:StringTable_NodeEnumerator =New StringTable_KeyEnumerator
		nodeenum._node =_FirstNode()
		Local mapenum:StringTable_MapEnumerator = New StringTable_MapEnumerator
		mapenum._enumerator = nodeenum
		Return mapenum
	End Method

	Method values:StringTable_MapEnumerator()
		Local nodeenum:StringTable_NodeEnumerator=New StringTable_ValueEnumerator
		nodeenum._node=_FirstNode()
		Local mapenum:StringTable_MapEnumerator=New StringTable_MapEnumerator
		mapenum._enumerator=nodeenum
		Return mapenum
	End Method

	Method copy:StringTable()
		Local map:StringTable = New StringTable

		map._root = _root.copy(nil)

		Return map
	End Method

	Method objectEnumerator:StringTable_NodeEnumerator()
		Local nodeenum:StringTable_NodeEnumerator=New StringTable_NodeEnumerator
		nodeenum._node=_FirstNode()
		Return nodeenum
	End Method

	Method _firstNode:StringTable_Node()
		Local node:StringTable_Node = Self._root
		While node._left <> nil
			node = node._left
		Wend
		Return node
	End Method

	Method _lastNode:StringTable_Node()
		Local node:StringTable_Node = self._root
		While node._right <> nil
			node = node._right
		Wend
		Return node
	End Method

	Method _findNode:StringTable_Node(key:String)
		Local node:StringTable_Node = self._root

		While node <> nil
			Local cmp:Int = key.compare(node._key)
			If cmp > 0 Then
				node = node._right
			ElseIf cmp < 0 Then
				node = node._left
			Else
				Return node
			EndIf
		Wend

		Return node
	End Method

	Method _removeNode(node:StringTable_Node)
		Local splice:StringTable_Node
		Local child:StringTable_Node

		If node._left = nil Then
			splice = node
			child  = node._right
		ElseIf node._right = nil Then
			splice = node
			child  = node._left
		Else
			splice = node._left
			While splice._right <> nil
				splice=splice._right
			Wend
			child=splice._left
			node._key=splice._key
			node._value=splice._value
		EndIf
		Local parent:StringTable_Node = splice._parent
		If child<>nil
			child._parent=parent
		EndIf
		If parent=nil
			_root=child
			Return
		EndIf
		If splice=parent._left
			parent._left=child
		Else
			parent._right=child
		EndIf

		If splice._color=BLACK _DeleteFixup child,parent
	End Method

	Method _insertFixup( node:StringTable_Node )
		Local uncle:StringTable_Node
		While node._parent._color = RED And node._parent._parent <> nil
			If node._parent = node._parent._parent._left Then
				uncle = node._parent._parent._right
				If uncle._color = RED Then
					node._parent._color = BLACK
					uncle._color = BLACK
					uncle._parent._color = RED
					node = uncle._parent
				Else
					If node = node._parent._right Then
						node = node._parent
						self._rotateLeft(node)
					EndIf
					node._parent._color = BLACK
					node._parent._parent._color = RED
					self._rotateRight(node._parent._parent)
				EndIf
			Else
				uncle = node._parent._parent._left
				If uncle._color = RED Then
					node._parent._color = BLACK
					uncle._color = BLACK
					uncle._parent._color = RED
					node = uncle._parent
				Else
					If node = node._parent._left Then
						node = node._parent
						self._rotateRight(node)
					EndIf
					node._parent._color = BLACK
					node._parent._parent._color = RED
					self._rotateLeft(node._parent._parent)
				EndIf
			EndIf
		Wend

		Self._root._color = BLACK
	End Method

	Method _rotateLeft(node:StringTable_Node)
		Local child:StringTable_Node = node._right
		node._right = child._left
		If child._left <> nil Then
			child._left._parent = node
		EndIf
		child._parent = node._parent
		If node._parent <> nil Then
			If node = node._parent._left Then
				node._parent._left = child
			Else
				node._parent._right = child
			EndIf
		Else
			_root = child
		EndIf
		child._left=node
		node._parent=child
	End Method

	Method _rotateRight( node:StringTable_Node )
		Local child:StringTable_Node=node._left
		node._left=child._right
		If child._right<>nil
			child._right._parent=node
		EndIf
		child._parent=node._parent
		If node._parent<>nil
			If node=node._parent._right
				node._parent._right=child
			Else
				node._parent._left=child
			EndIf
		Else
			_root=child
		EndIf
		child._right=node
		node._parent=child
	End Method

	Method _deleteFixup(node:StringTable_Node, parent:StringTable_Node)

		While node<>_root And node._color=BLACK
			If node=parent._left

				Local sib:StringTable_Node=parent._right

				If sib._color=RED
					sib._color=BLACK
					parent._color=RED
					_RotateLeft parent
					sib=parent._right
				EndIf

				If sib._left._color=BLACK And sib._right._color=BLACK
					sib._color=RED
					node=parent
					parent=parent._parent
				Else
					If sib._right._color=BLACK
						sib._left._color=BLACK
						sib._color=RED
						_RotateRight sib
						sib=parent._right
					EndIf
					sib._color=parent._color
					parent._color=BLACK
					sib._right._color=BLACK
					_RotateLeft parent
					node=_root
				EndIf
			Else
				Local sib:StringTable_Node=parent._left

				If sib._color=RED
					sib._color=BLACK
					parent._color=RED
					_RotateRight parent
					sib=parent._left
				EndIf

				If sib._right._color=BLACK And sib._left._color=BLACK
					sib._color=RED
					node=parent
					parent=parent._parent
				Else
					If sib._left._color=BLACK
						sib._right._color=BLACK
						sib._color=RED
						_RotateLeft sib
						sib=parent._left
					EndIf
					sib._color=parent._color
					parent._color=BLACK
					sib._left._color=BLACK
					_RotateRight parent
					node=_root
				EndIf
			EndIf
		Wend
		node._color=BLACK
	End Method

End Type

Private

Global nil:StringTable_Node = New StringTable_Node

nil._color  = StringTable.BLACK
nil._parent = nil
nil._left   = nil
nil._right  = nil

Type StringTable_KeyValue
	Field _key:String
	Field _value:String

	Method key:String()
		Return Self._key
	End Method

	Method value:String()
		Return Self._value
	End Method

End Type

Type StringTable_Node Extends StringTable_KeyValue
	Field _color:Byte
	Field _parent:StringTable_Node = nil
	Field _left:StringTable_Node   = nil
	Field _right:StringTable_Node  = nil

	Method nextNode:StringTable_Node()
		Local node:StringTable_Node = Self
		If node._right <> nil Then
			node = _right
			While node._left <> nil
				node = node._left
			Wend
			Return node
		EndIf

		Local parent:StringTable_Node=_parent
		While node = parent._right
			node = parent
			parent = parent._parent
		Wend
		Return parent
	End Method

	Method prevNode:StringTable_Node()
		Local node:StringTable_Node=Self
		If node._left <> nil Then
			node = node._left
			While node._right <> nil
				node = node._right
			Wend
			Return node
		EndIf
		Local parent:StringTable_Node=node._parent
		While node=parent._left
			node=parent
			parent=node._parent
		Wend
		Return parent
	End Method

	Method clear()
		self._parent = Null
		If self._left <> nil Then self._left.clear()
		If self._right <> nil Then self._right.clear()
	End Method

	Method copy:StringTable_Node(parent:StringTable_Node)
		Local t:StringTable_Node = New StringTable_Node
		t._key    = self._key
		t._value  = self._value
		t._color  = self._color
		t._parent = parent

		If _left <> nil then
			t._left=_left.Copy( t )
		EndIf

		If _right <> nil then
			t._right=_right.Copy( t )
		EndIf

		Return t
	End Method

End Type

Public

Type StringTable_NodeEnumerator
	Field _node:StringTable_Node

	Method hasNext:Byte()
		Return self._node <> nil
	End Method

	Method nextObject:Object()
		Local node:StringTable_Node = self._node
		self._node = self._node.nextNode()
		Return node
	End Method

End Type

Type StringTable_KeyEnumerator Extends StringTable_NodeEnumerator
	Method NextObject:Object()
		Local node:StringTable_Node = Self._node
		Self._node = Self._node.nextNode()

		Return node._key
	End Method
End Type

Type StringTable_ValueEnumerator Extends StringTable_NodeEnumerator
	Method NextObject:Object()
		Local node:StringTable_Node=_node
		_node=_node.NextNode()
		Return node._value
	End Method
End Type

Type StringTable_MapEnumerator
	Method ObjectEnumerator:StringTable_NodeEnumerator()
		Return _enumerator
	End Method
	Field _enumerator:StringTable_NodeEnumerator
End Type
