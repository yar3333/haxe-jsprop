import haxe.Serializer;
import haxe.Unserializer;

class BaseClass
{
    var r : Int;
	
	public function new(p:Int)
	{
		r = p;
		trace("MYVALUE "+ p);
	}
	
	function hxSerialize(s:Serializer)
	{
		trace("BaseClass.hxSerialize");
		s.serialize(r);
	}
	
	function hxUnserialize(s:Unserializer)
	{
		trace("BaseClass.hxUnserialize");
		r = s.unserialize();
	}
}


@:build(JsProp.all())
class TestClass extends BaseClass
{
	
    public var myPropGetSet(get, set) : Int;
    function get_myPropGetSet() return r;
    function set_myPropGetSet(v) return r=v;
    
	public var myPropGetNever(get, never) : Int;
    function get_myPropGetNever() return r;
	
	override function hxSerialize(s:Serializer) super.hxSerialize(s);
	override function hxUnserialize(s:Unserializer) super.hxUnserialize(s);
    
	public function new()
	{
		super(5);
		trace("TestClass.new: raw this.myPropGetSet = " + untyped __js__("this.myPropGetSet"));
		trace("TestClass.new: haxe myPropGetSet = " + myPropGetSet);
	}
}

typedef TestTypedef =
{
	public var myPropGetSet(default, default) : Int;
    public var myPropGetNever(default, never) : Int;
}

class Main
{
	static function main()
	{
		test(new TestClass());
		
		trace("");
		trace("Serializing test:");
		
		var klass = new TestClass();
		var s = Serializer.run(klass);
		trace("serialized = " + s);
		klass = Unserializer.run(s);
		test(klass);
		
		
		var c = new C(5);
	}
	
	static function test(klass:TestTypedef)
	{
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

