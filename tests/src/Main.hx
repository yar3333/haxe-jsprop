@:build(JsProp.all())
class TestClass
{
    public var r = 5;
	
    public var myPropGetSet(get, set) : Int;
    function get_myPropGetSet() return r;
    function set_myPropGetSet(v) return r=v;
    
	public var myPropGetNever(get, never) : Int;
    function get_myPropGetNever() return r;
    
	public function new()
	{
		trace("TestClass.new: raw this.myPropGetSet = " + untyped __js__("this.myPropGetSet"));
		trace("TestClass.new: haxe myPropGetSet = " + myPropGetSet);
	}
}

typedef TestTypedef =
{
    var r : Int;
	public var myPropGetSet(default, default) : Int;
    public var myPropGetNever(default, never) : Int;
}

class Main
{
	static function main()
	{
		var klass : TestTypedef = new TestClass();
		
		trace("Out must be " + klass.r);
		
		trace("raw klass.myPropGetSet = " + untyped __js__("klass.myPropGetSet"));
		trace("raw klass.myPropGetNever = " + untyped __js__("klass.myPropGetNever"));
		
		trace("haxe klass.myPropGetSet = " + klass.myPropGetSet);
		trace("haxe klass.myPropGetNever = " + klass.myPropGetNever);
		
		trace("Out must be 10");
		klass.myPropGetSet = 10;
		
		trace("haxe klass.myPropGetSet = " + klass.myPropGetSet);
		trace("haxe klass.myPropGetNever = " + klass.myPropGetNever);
	}
}

