# jsprop #

A build macro to generate support code for native js properties.
Add 'Object.defineProperty()' at the start of constructor.
Support get/set combinations which not assume to create real variable (get/set, get/never and never/set without @:isVar).

Usage
```
#!haxe
@:build(JsProp.all()) // generate support code for all properties
class Car
{
	var internalColor = "red";
	
	var color(get, set) : String;
	function get_color() return internalColor;
	function set_color(v) return internalColor = v;
}

@:build(JsProp.marked()) // generate support code for properties marked with '@:property' meta.
class Dog
{
	var internalColor = "brown";
	
	@:property
	var color(get, set) : String;
	function get_color() return internalColor;
	function set_color(v) return internalColor = v;
}
```
