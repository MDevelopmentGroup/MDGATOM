Include %sySystem

Class MDG.Request Extends %Persistent
{

/// FIXME - Windows specific
Parameter Path = "C:/temp/";

/// create broker in the current namespace
ClassMethod CreateBroker(broker) As %Status
{
    set File=##class(%File).%New()
    //set st=File.CreateDirectory("c:\temp"),st=File.%Save()
    set ns = $namespace, $namespace="%SYS"
    set status=##class(Security.Applications).Get(broker,.CSP)
    if status '=1 {
        write !,"Broker "_broker_" created for the namespace "_ns
        set cspProperties("AutheEnabled") = 64
        set cspProperties("NameSpace") = ns
        set cspProperties("DispatchClass") = "WEB.Broker"
        set cspProperties("IsNameSpaceDefault") = 0
        set tSC = ##Class(Security.Applications).Create(broker,.cspProperties)
        if $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
    }
    set $namespace=ns

    quit $$$OK
}

/// Получение областей
ClassMethod GetNamespaces() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim tNS As %String
    set str=""
    write "["
    //Get the list of namespaces
    do List^%SYS.NAMESPACE(.tList)
    set tNS=""
    for  {
        set tNS=$Order(tList(tNS),1,tValue)
        if tNS="" {quit}
        set str=str_""""_tNS_""","
    }
    write $Extract(str,1,*-1)
    write "]"
    quit tSC
}

ClassMethod GetPath() As %Status
{
    #dim Path=""

    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set Path=obj.TempDir_obj.NameSpace
    set ProxyObject=##class(%ZEN.proxyObject).%New()
    set ProxyObject.Path=Path
    set ProxyObject.Dir=obj.TempDir
    do ProxyObject.%ToJSON()
    set File=##class(%File).%New()
    do File.CreateDirectory(obj.TempDir)

    do File.CreateDirectory(File.NormalizeDirectory( Path))
    do ..WriteClassFiles(obj.NameSpace,Path)
    set defapp = $System.CSP.GetDefaultApp(obj.NameSpace)
    set linkPath = ..GetAppPath(defapp)
    /*
    FIXME- currently works only for the local project under Windows!
    */
    if $$$ISWINDOWS {
        set mklPath = $Replace(Path,"/","\")
        //w !,"lp - "_linkPath
        do $zf(-1,"mklink /J "_mklPath_"\WebApps "_linkPath)
        //w !,"mklink /J "_mklPath_"/WebApps "_linkPath
        //do ..WriteWebFiles(obj.NameSpace,Path)
    } else {
        /// FIXME - TODO
        set mklPath = $Replace(Path,"\","/")
        //w "Tyt",!
       // w "ln -s "_linkPath_" "_mklPath_"/WebApps ",!
         do $zf(-1,"ln -s "_linkPath_" "_mklPath_"/WebApps ")
        //ln -s H:\users\User\Downloads C:\Users\User\Downloads
    }
    do ..ROUTINE(obj.NameSpace,Path)

    quit $$$OK
}

ClassMethod GetAppPath(cspapp)
{

    set ns = $namespace
    set $namespace="%SYS"
    kill csp
    set csp = ##class(Security.Applications).Get(cspapp,.csp)
    set $namespace=ns

    quit $get(csp("Path"))
}

ClassMethod WriteWebFiles(NS, Path) As %Status
{
    set Path=Path_"/Web"
    #dim st As %Status=$$$OK

    // получаем веь приложение по умолчанию для области NS
    set defapp = $System.CSP.GetDefaultApp(NS)
    set ns = $namespace, $namespace="%SYS"
    kill csp
    set csp = ##class(Security.Applications).Get(defapp,.csp)
    set $namespace=ns
    set File=##class(%File).%New()
    set status=File.CreateDirectory(Path)
    set Path=Path_defapp
    set status=File.CreateDirectory(Path)
    set status=File.CopyDir($get(csp("Path")),Path,1)

    quit status
}

ClassMethod WriteClassFile(NS, Class, text) As %Status
{
    set Path=..#Path_NS_"/Classes"
    set File=##class(%File).%New()
    set List=$ListFromString(Class,".")
    set tempPath=Path_"/"
    for i=1:1:$ListLength(List)-1 {
        set tempPath=tempPath_$List(List,i)_"/"
        if $$$ISWINDOWS {}
        else{
	        set tempPath=$REPLACE(tempPath,"/",".")
	        }
        do File.CreateDirectory(tempPath)
    }
    set file=##class(%Stream.FileBinary).%New()
    set file.Filename=tempPath_$List(List,$ListLength(List))_".cls"
    set status=file.Write($ZConvert(text,"O","UTF8"))
    set status=file.%Save()

    quit $$$OK
}

ClassMethod WriteClassFiles(NS, Path) As %Status
{
    set Path=Path_"/Classes"
    #dim st As %Status=$$$OK

    set sn = $namespace
    set $namespace = NS
    set File=##class(%File).%New()
    do File.CreateDirectory(Path)

    set s=##class(%SQL.Statement).%New()
    set sql = "SELECT * FROM %Dictionary.ClassDefinition  where NOT id %STARTSWITH '%' and system <>4"
    set status=s.%Prepare(sql)
    set rs=s.%Execute()
    while rs.%Next() {
        set tempPath=Path_"/"
        set List=$ListFromString(rs.%Get("ID"),".")
        for i=1:1:$ListLength(List)-1 {
            set tempPath=tempPath_$List(List,i)_"/"
            do File.CreateDirectory(tempPath)
        }
        set tSC=##class(%Compiler.UDL.TextServices).GetTextAsStream(NS,rs.%Get("ID"),.tStream)
        set file=##class(%Stream.FileBinary).%New()
        set file.Filename=tempPath_$List(List,$ListLength(List))_".cls"
        set status=file.Write($ZConvert(tStream.Read(tStream.Size),"O","UTF8"))
        set status=file.%Save()
        kill file
        if $$$ISWINDOWS {}
            else {
	                     do $zf(-1,"chmod 777 "_tempPath_$List(List,$ListLength(List))_".cls")
	            }
    }
    set $namespace=sn

    quit status
}

/// Method returns the class text
ClassMethod GetClass() As %Status
{
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    set temp=##class(%ZEN.proxyObject).%New()
    #dim tStream As %Stream.Character

    try {
        set tSC=##class(%Compiler.UDL.TextServices).GetTextAsStream(obj.NameSpace,obj.ClassName,.tStream)
        if $$$ISERR(tSC) quit
        set temp.SourceText=tStream.Read(tStream.Size)
        set temp.NameSpace=obj.NameSpace
        set temp.ClassName=obj.ClassName
        do temp.%ToJSON()
    }
    catch (e) {
        set tSC=e.AsStatus()
    }

    quit tSC
}

///  Список классов
ClassMethod GetClassList() As %Status
{
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn = $namespace
    set $namespace = obj.NameSpace
    set s=##class(%SQL.Statement).%New()
    set sql = "SELECT * FROM %Dictionary.ClassDefinition  where NOT id %STARTSWITH '%' and system <>4"
    set status=s.%Prepare(sql)
    set str = ""
    set rs=s.%Execute()
    write "["
    while rs.%Next() {
        set str = str_ "{""Name"":"""_rs.%Get("ID")_"""},"
    }
    write $Extract(str,1,*-1)
    write "]"
    set $namespace = sn

    quit $$$OK
}

ClassMethod UpdateClass() As %Status
{
    /* Пример приходящих данных
    data: { namespace: "MDG-DEV",
          text: "Class Example.Studio Extends (%Persistent,%Populate)'+'\r\n{'+'\r\n//hgjgjgjgh'+'\r\n}",
          nameClass: "Example.Studio"
          }
    */
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn=$namespace
    set $namespace= obj.namespace
    set status=##class(%Dictionary.ClassDefinition).%ExistsId(obj.nameClass)
    if ('st){
        set nc = ##class(%Dictionary.ClassDefinition).%New(obj.nameClass)
        set nc.Super = ""
        set nc.Abstract = ""
        set st = nc.%Save()
        do ..WriteClassFiles(obj.namespace,obj.TempDir_obj.namespace)
    }
    set stream=##class(%Stream.GlobalCharacter).%New()
    do stream.Write($ZConvert(obj.text,"I","UTF8"))
    set status= ##class(%Compiler.UDL.TextServices).SetTextFromStream(obj.namespace, obj.nameClass, stream)
    write status
    set $namespace=sn

    quit $$$OK
}

/// Cоздание класса
ClassMethod CreateClass() As %Status
{
    /* Пример приходящих данных
    data: { namespace: "MDG-DEV",
          nameClass: "Example.Studio",
          Super: "%Persistent,%Populate",
          Abstract: "0",
          Description: "This is TestClass"
          }
    */
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn = $namespace
    set $namespace = obj.namespace
    set o = ##class(%Dictionary.ClassDefinition).%New(obj.nameClass)
    set o.Super = obj.Super
    set o.Abstract = obj.Abstract
    set o.Description = obj.Description
    set status = o.%Save()
    w status
    if status {
    set tSC=##class(%Compiler.UDL.TextServices).GetTextAsStream(obj.namespace,obj.nameClass,.tStream)
    set file=##class(%Stream.FileBinary).%New()
    set Dir=##class(%File).%New()
    set Path=obj.Path_obj.namespace_"/Classes"
    set tempPath=Path_"/"

    set List=$ListFromString(obj.nameClass,".")
    for i=1:1:$ListLength(List)-1 {
        set tempPath=tempPath_$List(List,i)_"/"
        do Dir.CreateDirectory(tempPath)
    }
    set file.Filename=tempPath_$List(List,$ListLength(List))_".cls"
    set status=file.Write($ZConvert(tStream.Read(tStream.Size),"O","UTF8"))
    set status=file.%Save()
    kill file
    }
    set $namespace = sn

    quit $$$OK
}

ClassMethod CompilationClass() As %Status
{
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn = $namespace
    set $namespace = obj.namespace
    set str = ""

    set status=$system.OBJ.Compile(obj.nameClass)
    if $$$ISERR(status) {
        write "[{""""ErrorText"":"
        do $System.Status.DisplayError(status) write """}]"
    }
    set $namespace = sn

    quit $$$OK
}

ClassMethod DeleteClass() As %Status
{
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn = $namespace
    set $namespace = obj.namespace
    do ##class(%Studio.ClassMgr).Delete(obj.nameClass)
    set $namespace = sn

    quit $$$OK
}

ClassMethod CreateMethod() As %Status
{
    /* Пример приходящих данных
    data: { namespace: "MDG-DEV",
      nameClass: "Example.Studio",
      ClassMethod: "1",
      nameMethod: "AtomIO",
      ReturnType: "%Status",
      Private: "0",
      Final: "1"
      }
    */
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn = $namespace
    set $namespace = obj.namespace
    set method=##class(%Dictionary.MethodDefinition).%New(obj.nameClass)
    set method.ClassMethod=obj.ClassMethod
    set method.Name=obj.nameMethod
    set method.ReturnType = obj.ReturnType
    set method.Private = obj.Private
    set method.Final = obj.Final
    set status=method.%Save()
    set $namespace = sn

    quit $$$OK
}

ClassMethod CreateProperty() As %Status
{

    /* Пример приходящих данных
    data: { namespace: "MDG-DEV",
      nameClass: "Example.Studio",
      nameProperty: "test123",
      Type: "%String",
      Relationship: "0",
      Required: "1",
      Calculated: "0"
      }
    */
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set sn = $namespace
    set $namespace = obj.namespace
    set property=##class(%Dictionary.PropertyDefinition).%New(obj.nameClass)
    set property.Name = obj.nameProperty
    set property.Description = obj.Description
    set property.Type = obj.Type
    set property.Collection = obj.Collection
    //Отношение
    set property.Relationship = obj.Relationship
    set property.Required = obj.Required
    set property.Calculated = obj.Calculated
    //Запись параметров
    for i=1:1:obj.Parameter.Size{
        do property.Parameters.SetAt(obj.Parameter.GetAt(i).Data,obj.Parameter.GetAt(i).Name)
    }
    set status=property.%Save()
    set $namespace = sn

    quit $$$OK
}

/// Получение параметров
ClassMethod GetParameters() As %Status
{
    $$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
    set qqq = "%"_obj.Parameters
    set s=##class(%Library.ResultSet).%New("%Dictionary.ParameterDefinitionQuery:Summary")
    do s.Execute(qqq)
    set str = ""
    write "["
    while s.Next() {
        set str = str_ "{""Name"":"""_s.Get("Name")_"""},"
    }
    write $Extract(str,1,*-1)
    write "]"

    quit $$$OK
}

ClassMethod ROUTINE(namespace, Path) As %Status
{
    #dim st As %Status=$$$OK

    set Path=Path_"/PROGRAMS"
    set File=##class(%File).%New()
    do File.CreateDirectory(Path)
    set routine=##class(%ResultSet).%New("%Library.Routine:RoutineList")
    set status=routine.Execute("",1,"INT",namespace)
    while routine.Next() {
        set ns=$namespace
        set $namespace=namespace
        set temp=##class(%Routine).%OpenId(routine.Get("Name"))
        set $namespace=ns
        set tempPath=Path_"/"
        set type=$E(routine.Get("Name"),$LENGTH(routine.Get("Name"))-2,*)
        set file=##class(%Stream.FileBinary).%New()
        if (type="BAS"){
	set file.Filename=tempPath_routine.Get("Name")
        	set status=file.CopyFrom(temp)
        	set status=file.%Save()
	}
        if (type="MAC"){
	set file.Filename=tempPath_routine.Get("Name")
        	set status=file.CopyFrom(temp)
        	set status=file.%Save()
	        }
        if (type="INT"){
	              set List=$ListFromString(routine.Get("Name"),".")
        for i=1:1:$ListLength(List)-3 {
            set tempPath=tempPath_$List(List,i)_"/"
            do File.CreateDirectory(tempPath)
        }

        set file.Filename=tempPath_$List(List,$ListLength(List)-2)_"."_$List(List,$ListLength(List)-1)_"."_$ZConvert($List(List,$ListLength(List)),"L")
        set status=file.CopyFrom(temp)
        set status=file.%Save()
        kill file
	}

    }

    quit status
}

ClassMethod Refresh() As %Status
{
	#dim st As %Status=$$$OK
	$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
	set File=##class(%File).%New()
	set st= File.RemoveDirectoryTree(obj.Path)
	set st= File.RemoveDirectoryTree(obj.Path)
	do ..WriteClassFiles(obj.NameSpace,obj.Path)
	do ..ROUTINE(obj.NameSpace,obj.Path)
	w "{""status"":"_st_"}"
	quit 1
}

ClassMethod CompileAll() As %Status
{
	set status=$$$OK
	$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
	set List=##class(%Library.ListOfDataTypes).%New()
	s Dir=obj.CurrentDir_"/Classes"

	d ..FileList(Dir,List)
	For i=1:1:List.Size{
		set item=List.GetAt(i)
		if $E(item,$LENGTH(item)-3,*)=".cls"{
			set classname=$E($REPLACE($REPLACE($E(item,$LENGTH(Dir)+2,*),"\","."),"/","."),0,*-4)
			    set sn = $namespace
    			set $namespace = obj.NameSpace
    			set status=$system.OBJ.Compile(classname)

    			set $namespace = sn
		}
	}
	do ..ROUTINE(obj.NameSpace,obj.CurrentDir)
	quit $$$OK
}

ClassMethod SaveAll() As %Status
{
	set status=$$$OK
	$$$THROWONERROR(st,##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(%request.Content,,.obj,1))
	set List=##class(%Library.ListOfDataTypes).%New()
	s Dir=obj.CurrentDir_"/Classes"

	d ..FileList(Dir,List)
	For i=1:1:List.Size{
		set item=List.GetAt(i)
		if $E(item,$LENGTH(item)-3,*)=".cls"{
			set classname=$E($REPLACE($REPLACE($E(item,$LENGTH(Dir)+2,*),"\","."),"/","."),0,*-4)
			set sn = $namespace
    			set $namespace = obj.NameSpace
			set st=##class(%Dictionary.ClassDefinition).%ExistsId(classname)
			set $namespace=sn
			if (st)
			{
				set sn = $namespace
    				set $namespace = obj.NameSpace
				set tfile=##class(%Stream.FileBinary).%New()
				set tfile.Filename=item
				 set stream=##class(%Stream.GlobalCharacter).%New()
    				do stream.Write($ZConvert(tfile.Read(tfile.Size),"I","UTF8"))
    				set status= ##class(%Compiler.UDL.TextServices).SetTextFromStream(obj.NameSpace, classname, stream)
    				set $namespace=sn
			}
			else
			{
			set sn = $namespace
    			set $namespace = obj.NameSpace
    			set class = ##class(%Dictionary.ClassDefinition).%New(classname)
    			set class.Super = ""
    			set class.Abstract = ""
    			set class.Description = ""
    			set status = class.%Save()
    			if status {
	    			set tfile=##class(%Stream.FileBinary).%New()
				set tfile.Filename=item
				set stream=##class(%Stream.GlobalCharacter).%New()
    				do stream.Write($ZConvert(tfile.Read(tfile.Size),"I","UTF8"))
    				set status= ##class(%Compiler.UDL.TextServices).SetTextFromStream(obj.NameSpace, classname, stream)
	    		}
    			set $namespace=sn
			}
		}
	}
	w "{""status"":"_status_"}"
	Quit $$$OK
}

ClassMethod FileList(Dir, ByRef list As %ListOfDataTypes) As %Status
{
	s result=##class(%ResultSet).%New("%Library.File:FileSet")
	d result.Execute(Dir)
	while result.Next()
	{
		if result.Get("Type")="F"{do list.Insert(result.Get("Name"))}
		else{do ..FileList(result.Get("Name"),list)}
	}
	quit $$$OK
}

<Storage name="Default">
<Data name="RequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^MDG.RequestD</DataLocation>
<DefaultData>RequestDefaultData</DefaultData>
<IdLocation>^MDG.RequestD</IdLocation>
<IndexLocation>^MDG.RequestI</IndexLocation>
<SequenceNumber>23</SequenceNumber>
<StreamLocation>^MDG.RequestS</StreamLocation>
<Type>%Library.CacheStorage</Type>
</Storage>
}
