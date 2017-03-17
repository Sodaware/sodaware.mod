' ------------------------------------------------------------------------------
' -- src/dependency_injector.bmx
' --
' -- Manages injectable fields for object types and injects data into them.
' --
' -- This file is part of sodaware.mod (https://www.sodaware.net/sodaware.mod/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See LICENSE for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.reflection
Import sodaware.ObjectBag

Import "i_injectable.bmx"

''' <summary>
''' Static class that manages injectable fields for object types and injects data 
''' into them.
''' </summary>
Type DependencyInjector

	' -- Dependency fields
	Global _injectableObjects:TMap = New TMap
	
	
	' ------------------------------------------------------------
	' -- Adding dependencies
	' ------------------------------------------------------------
	
	Function dependsOn(o:Object, objectType:TTypeId, fieldName:String)
		
		Local objectInfo:InjectableObject = _fetchObject(o)
		Local injectInto:TField = TTypeId.ForObject(o).FindField(fieldName)
		
		Assert(objectType <> Null And injectInto <> Null)
		
		_addInjectableField(objectInfo, objectType, injectInto)
	End Function
	
	Function _addInjectableField(objectInfo:InjectableObject, objectType:TTypeId, injectInto:TField)
		objectInfo._iinjectable_dependencies.add(objectType)
		objectInfo._iinjectable_dependencyMap.Insert(objectType, injectInto)
	End Function
	
	
	' ------------------------------------------------------------
	' -- Querying dependencies
	' ------------------------------------------------------------
	
	Function hasDependencies:Byte(o:Object)
		Local objectInfo:InjectableObject = _fetchObject(o)
		Return objectInfo.hasDependencies()
	End Function
	
	Function getDependencies:ObjectBag(o:Object)
		Local objectInfo:InjectableObject = _fetchObject(o)
		Return objectInfo.getDependencies()
	End Function
	
	Function hasDependency:Byte(o:Object, objectType:TTypeId)
		Local objectInfo:InjectableObject = _fetchObject(o)
		Return objectInfo.hasDependency(objectType)
	End Function
	
	
	' ------------------------------------------------------------
	' -- Injecting dependencies
	' ------------------------------------------------------------
	
	Function inject(o:Object, objectType:TTypeId, obj:Object)
			
		Local objectInfo:InjectableObject = _fetchObject(o)
		Assert(objectInfo <> Null)
		
		' Get the field to inject into
		Local injectableField:TField = TField(objectInfo._iinjectable_dependencyMap.ValueForKey(objectType))
		
		' Do nothing if field doesn't exist
		If injectableField = Null Then Return
		
		' Inject
		injectableField.Set(o, obj)
		
	End Function
	
	Function injectAll(o:Object, objectList:Object[])
		
		Local objectInfo:InjectableObject = _fetchObject(o)
		Assert(objectInfo <> Null)
		
		For Local toInject:Object = EachIn objectList
			
			Local objectType:TTypeId = TTypeId.ForObject(toInject)
			Local injectableField:TField = TField(objectInfo._iinjectable_dependencyMap.ValueForKey(objectType))	
			
			
			If injectableField <> Null Then injectableField.Set(o, toInject)
		Next
		
		objectInfo._injected = True
		
	End Function
	
	
	' ------------------------------------------------------------
	' -- Automatic injection
	' ------------------------------------------------------------
	
	' If called, will get dependencies from meta data
	Function addInjectableFields(o:Object)
	
		' Get injection lookup for this object
		Local objectInfo:InjectableObject = _fetchObject(o)

		' Get the object's type
		Local objType:TTypeId = TTypeId.ForObject(o)

		' Get all fields
		DependencyInjector._addInjectableFieldsForType(objectInfo, objType)
		
		' Add parent types
		objType = objType.SuperType()
		While objType <> Null
			DependencyInjector._addInjectableFieldsForType(objectInfo, objType)
			objType = objType.SuperType()
		WEnd
		
	End Function
	
	Function _addInjectableFieldsForType(objectInfo:InjectableObject, objType:TTypeId)
		For Local fld:TField = EachIn objType.Fields()
			If fld.MetaData("injectable") Then
				objectInfo._addInjectableField(fld.TypeId(), fld)
			End If
		Next
	End Function
	
	Function _fetchObject:InjectableObject(o:Object)
		Local objectLookup:InjectableObject = InjectableObject(_injectableObjects.ValueForKey(o))
		If objectLookup = Null Then
			objectLookup = InjectableObject.Create(o)
			_injectableObjects.Insert(o, objectLookup)
		End If
		Return objectLookup
	End Function
	
End Type


Private

Type InjectableObject Extends IInjectable
	
	Field _injected:Byte = False

	Function Create:InjectableObject(o:Object)
		Local this:InjectableObject = New InjectableObject
		this._iiinjectable_object = o
		Return this
	End Function

End Type