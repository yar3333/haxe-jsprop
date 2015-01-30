import haxe.macro.Context;
import haxe.macro.Expr;
using Lambda;

class JsProp
{
	public static macro function marked() : Array<Field>
	{
		if (Context.defined("js"))
		{
			var klass = Context.getLocalClass().get();
			var fields = Context.getBuildFields();
			var changed = false;
			for (field in fields)
			{
				if (hasMeta(field, ":property"))
				{
					if (processProperty(field, fields, klass.superClass != null)) changed = true;
				}
			}
			if (changed) return fields;
		}
		return null;
	}
	
	public static macro function all() : Array<Field>
	{
		if (Context.defined("js"))
		{
			var klass = Context.getLocalClass().get();
			var fields = Context.getBuildFields();
			var changed = false;
			for (field in fields)
			{
				switch (field.kind)
				{
					case FieldType.FProp(_, _, _, _):
						if (processProperty(field, fields, klass.superClass != null)) changed = true;
					case _:
				}
			}
			if (changed) return fields;
		}
		return null;
	}
	
	static function processProperty(field:Field, fields:Array<Field>, hasSuper:Bool) : Bool
	{
		switch (field.kind)
		{
			case FieldType.FProp(get, set, t, e):
				var getter = "get_" + field.name;
				var setter = "set_" + field.name;
				
				switch ([ get, set, hasMeta(field, ":isVar")])
				{
					case [ "get", "set", false ]:
						var constructor = getConstructorFunction(fields, hasSuper);
						var code = macro (untyped Object).defineProperty(this, $v{field.name}, { get:function() return $i{getter}(), set:function(v) $i{setter}(v) });
						prependCode(constructor, code);
						field.kind = FieldType.FProp("default", "default", t, e);
						return true;
						
					case [ "get", "never", false ]:
						var constructor = getConstructorFunction(fields, hasSuper);
						var code = macro (untyped Object).defineProperty(this, $v{field.name}, { get:function() return $i{getter}() });
						prependCode(constructor, code);
						field.kind = FieldType.FProp("default", "never", t, e);
						return true;
						
					case [ "never", "set", false ]:
						var constructor = getConstructorFunction(fields, hasSuper);
						var code = macro (untyped Object).defineProperty(this, $v{field.name}, { set:function(v) $i{setter}(v) });
						prependCode(constructor, code);
						field.kind = FieldType.FProp("never", "default", t, e);
						return true;
						
					case [ "default"|"null"|"never", "default"|"null"|"never", _ ]:
						// nothing to do
						
					case _:
						Context.fatalError("JsProp: unsupported get/set combination. Supported: (get,set), (get,never) and (never,set) all without @:isVar.", field.pos);
				}
				
			case _:
				Context.fatalError("JsProp: unsupported type (must be a property).", field.pos);
		}
		return false;
	}
	
	static function prependCode(f:Function, code:Expr)
	{
		switch (f.expr.expr)
		{
			case EBlock(exprs):
				exprs.unshift({ expr:code.expr, pos:code.pos });
				
			case _:
				f.expr = macro { $code; ${f.expr}; };
		}
	}
	
	
	static function getConstructorFunction(fields:Array<Field>, hasSuper:Bool) : Function
	{
		var constructor : Field = null;
		
		for (field in fields)
		{
			if (field.name == "new")
			{
				constructor = field;
				break;
			}
		}
		
		if (constructor == null)
		{
			constructor = createMethod("new", [], macro : Void, hasSuper ? macro { super(); } : macro { } );
			fields.push(constructor);
		}
		
		switch (constructor.kind)
		{
			case FieldType.FFun(f):
				return f;
				
			case _:
				Context.fatalError("JsProp: unexpected constructor type '" + constructor.kind + "'.", constructor.pos);
				return null;
		}
	}
	
	static function hasMeta(f:{ meta:Metadata }, m:String) : Bool
	{
		if (f.meta == null) return false;
		for (mm in f.meta)
		{
			if (mm.name == m) return true;
		}
		return false;
	}
	
	static function createMethod(name:String, args:Array<FunctionArg>, ret:Null<ComplexType>, expr:Expr) : Field
	{
		return
		{
			  name : name
			, access : [ Access.APublic ]
			, kind : FieldType.FFun
						({
							  args : args
							, ret : ret
							, expr : expr
							, params : []
						})
			, pos : expr.pos
		};
	}
}
