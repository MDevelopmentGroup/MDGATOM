Class WEB.Broker Extends %CSP.REST
{

XData UrlMap
{
<Routes>
 
    <Route Url="/namespaces" Method="POST" Call="MDG.Request:GetNamespaces" />
    <Route Url="/namespaces/classlist" Method="POST" Call="MDG.Request:GetClassList" />
    <Route Url="/namespaces/classname" Method="POST" Call="MDG.Request:GetClass" />
    <Route Url="/updateclass" Method="POST" Call="MDG.Request:UpdateClass" />
    <Route Url="/createclass" Method="POST" Call="MDG.Request:CreateClass" />
    <Route Url="/compilationclass" Method="POST" Call="MDG.Request:CompilationClass" />
    <Route Url="/deleteclass" Method="POST" Call="MDG.Request:DeleteClass" />
    <Route Url="/createmethod" Method="POST" Call="MDG.Request:CreateMethod" />
    <Route Url="/createproperty" Method="POST" Call="MDG.Request:CreateProperty" />
    <Route Url="/getparameter" Method="POST" Call="MDG.Request:GetParameters"/>
    <Route Url="/getpath" Method="POST" Call="MDG.Request:GetPath"/>
    <Route Url="/refresh" Method="POST" Call="MDG.Request:Refresh"/>
    <Route Url="/saveall" Method="POST" Call="MDG.Request:SaveAll"/>
    <Route Url="/compileall" Method="POST" Call="MDG.Request:CompileAll"/>
    
</Routes>
}

}

