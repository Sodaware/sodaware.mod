' ------------------------------------------------------------------------------
' -- src/i_injectable.bmx
' --
' -- Interface that all injectable objects should extend. Adds some hidden
' -- fields to store injectable data.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.map
Import brl.reflection
Import sodaware.ObjectBag

''' <summary>
''' Interface that all injectable objects should extend. Adds some hidden
''' fields to store injectable data.
''' </summary>
Type IInjectable
	
	' -- Dependency fields
	Field _iiinjectable_object:Object			= Self
	Field _iinjectable_dependencies:ObjectBag	= New ObjectBag
	Field _iinjectable_dependencyMap:TMAP		= New TMap
	
	
	' ------------------------------------------------------------
	' -- Querying dependencies
	' ------------------------------------------------------------
	
	''' <summary>Check if this object has any dependencies.</summary>
	''' <return>True if object has dependencies, false if not.</return>
	Method hasDependencies:Byte()
		Return (Self._iinjectable_dependencies.getSize() > 0)
	End Method
	
	''' <summary>Get an ObjectBag of all TTypeId's this object depends on.</summary>
	''' <return>All types this object depends on.</return>
	Method getDependencies:ObjectBag()
		Return Self._iinjectable_dependencies
	End Method
	
	''' <summary>Check if this object has a dependency of a specific type.</summary>
	''' <param name="objectType">The type to test for.</param>
	''' <return>True if this object depends on `objectType`, false if not.</return>
	Method hasDependency:Byte(objectType:TTypeId)
		Return Self._iinjectable_dependencies.contains(objectType)
	End Method
	
	
	' ------------------------------------------------------------
	' -- Injecting dependencies
	' ------------------------------------------------------------
	
	''' <summary>Inject a dependency object into this object's field.</summary>
	''' <param name="objectType">The TTypeId of the object being injected.</param>
	''' <param name="obj">The object to be injected.</param>
	Method inject(objectType:TTypeId, obj:Object)
		
		' Get the field to inject into
		Local injectableField:TField = TField(Self._iinjectable_dependencyMap.ValueForKey(objectType))
		
		' Do nothing if field doesn't exist
		If injectableField = Null Then Return
		
		' Inject
		injectableField.Set(Self, obj)
		
	End Method
	
		
	' ------------------------------------------------------------
	' -- Adding dependency data
	' ------------------------------------------------------------
	
	Method _dependsOn(objectType:TTypeId, fieldName:String)
		
		Local injectInto:TField = TTypeId.ForObject(Self).FindField(fieldName)
		
		Assert(objectType <> Null And injectInto <> Null)
		
		Self._addInjectableField(objectType, injectInto)
		
	End Method
	
	Method _addInjectableField(objectType:TTypeId, injectInto:TField)
		Self._iinjectable_dependencies.add(objectType)
		Self._iinjectable_dependencyMap.Insert(objectType, injectInto)
	End Method
	
	
	' ------------------------------------------------------------
	' -- Automatic injection
	' ------------------------------------------------------------
	
	''' <summary>Update the list of injectable fields for this object.</summary>
	Method _addInjectableFields()
		
		Local objType:TTypeId = TTypeId.ForObject(Self)
		For Local fld:TField = EachIn objType.Fields()
			If fld.MetaData("injectable") Then
				Self._addInjectableField(fld.TypeId(), fld)
			End If
		Next
	
	End Method
	
End Type
