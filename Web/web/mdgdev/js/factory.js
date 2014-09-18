angular.module('FactoryModule',[])
	.factory('One2Factory',['$http',function($http){return {
		Create:function(data)   {return $http.post('/broker/mdgdev/One2/Create',data);},
		Update:function(data)   {return $http.post('/broker/mdgdev/One2/Update',data);},
		Delete:function(ID)   {return $http.delete('/broker/mdgdev/One2/Delete/'+ID);},
		Get:function(ID)      {return $http.get('/broker/mdgdev/One2/Get/'+ID);},
		GetAll:function()      {return $http.get('/broker/mdgdev/One2/GetAll');}
		}}])