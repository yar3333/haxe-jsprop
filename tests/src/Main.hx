@:build(JsProp.all())
class Main
{
    //@:property
    var myPropGetSet(get, set) : Int;
    function get_myPropGetSet() return 1;
    function set_myPropGetSet(v) return v;
    
	/*@:property
    var myPropDefSet(default, set) : Int;
    function set_myPropDefSet(v) return v;*/
	
	// unsupported
	//@:property
    //var myPropGetDef(get, default) : Int;
    //function get_myPropGetDef() return 2;
    
	//@:property
    var myPropGetNull(get, null) : Int;
    function get_myPropGetNull() return 3;
	
	function new()
	{
		trace("constructor " + untyped __js__("this.myPropGetSet"));
	}
	
	static function main()
	{
		var m = new Main();
		trace("outer " + untyped __js__("m.myPropGetSet"));
	}
}
