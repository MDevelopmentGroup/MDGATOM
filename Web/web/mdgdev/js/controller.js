 function ViewOne2Ctrl($rootScope,$scope,$routeParams,One2Factory){
		$scope.GetOne2=function(){
		One2Factory.GetAll().success(function(data){$scope.One2s=data.children;});}; 
		$scope.GetOne2();$scope.Delete=function(ID){One2Factory.Delete(ID).success(function(){$scope.GetOne2();})};
	} 
 function CreateOne2Ctrl($rootScope,$scope,$routeParams,One2Factory){
		$scope.Submit=function(data){ One2Factory.Create(data).success(function(){location.href='#/One2';}); }
		} 
 function UpdateOne2Ctrl($rootScope,$scope,$routeParams,One2Factory){
		$scope.Submit=function(data){ One2Factory.Update(data).success(function(){location.href='#/One2';}); };
		$scope.Get=function(){
		One2Factory.Get($routeParams.ID).success(function(data){$scope.One2=data.children[0];});
		}
		$scope.Get();
		} 
