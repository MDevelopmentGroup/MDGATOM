angular.module('MDG',['ngCookies','ngResource','ngRoute','ngSanitize','ngAnimate','mgcrea.ngStrap','FactoryModule'
]).config(['$routeProvider',  function($routeProvider) { $routeProvider.
	when('/One2',{templateUrl: 'partials/ViewOne2.html', controller: ViewOne2Ctrl}).
	when('/CreateOne2',{templateUrl: 'partials/One2.html', controller: CreateOne2Ctrl}).
	when('/UpdateOne2/:ID',{templateUrl: 'partials/One2.html', controller: UpdateOne2Ctrl}).
	otherwise({redirectTo: '/One2'});}])
.config(function($datepickerProvider) { angular.extend($datepickerProvider.defaults, { dateFormat: 'MM/dd/yyyy', startWeek: 1 }); }) .config(function($timepickerProvider) { angular.extend($timepickerProvider.defaults, { timeFormat: 'HH:mm:ss', length: 4 }); })