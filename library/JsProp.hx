import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
using Lambda;

private typedef SuperClass = Null<{ t:Ref<ClassType>, params:Array<Type> }>;

class JsProp
{
	public static macro function marked() : Array<Field>
	{
		if (Context.defined("js"))
		{
			var klass = Context.getLocalClass().get();
			var fields = Context.getBuildFields();
			var codes = [];
			for (field in fields)
			{
				if (hasMeta(field, ":property"))
				{
					var t = getDefinePropertyCode(field);
					if (t != null) codes.push(t);
				}
			}
			if (codes.length > 0)
			{
				addDeinePropertyCode(fields, klass.superClass, codes);
				return fields;
			}
		}
		return null;
	}
	
	public static macro function all() : Array<Field>
	{
		if (Context.defined("js"))
		{
			var klass = Context.getLocalClass().get();
			var fields = Context.getBuildFields();
			var codes = [];
			for (field in fields)
			{
				switch (field.kind)
				{
					case FieldType.FProp(_, _, _, _):
						var t = getDefinePropertyCode(field);
						if (t != null) codes.push(t);
					case _:
				}
			}
			if (codes.length > 0)
			{
				addDeinePropertyCode(fields, klass.superClass, codes);
				return fields;
			}
		}
		return null;
	}
	
	static function addDeinePropertyCode(fields:Array<Field>, superClass:SuperClass, codes:Array<Expr>)
	{
		var code = macro $b{codes};
		prependCode(getConstructorFunction(fields, superClass), code);
		prependCode(getHxUnserializeFunction(fields, superClass), code);
		ensureHxSerializeFunctionExists(fields, superClass);
	}
	
	static function getDefinePropertyCode(field:Field) : Expr
	{
		switch (field.kind)
		{
			case FieldType.FProp(get, set, t, e):
				var getter = "get_" + field.name;
				var setter = "set_" + field.name;
				
				switch ([ get, set, hasMeta(field, ":isVar")])
				{
					case [ "get", "set", false ]:
						ensureNoExpr(e, field.pos);
						field.kind = FieldType.FProp("default", "default", t, e);
						return macro (untyped Object).defineProperty(this, $v{field.name}, { get:function() return $i{getter}(), set:function(v) $i{setter}(v) });
						
					case [ "get", "never", false ]:
						ensureNoExpr(e, field.pos);
						field.kind = FieldType.FProp("default", "never", t, e);
						return macro (untyped Object).defineProperty(this, $v{field.name}, { get:function() return $i{getter}() });
						
					case [ "never", "set", false ]:
						ensureNoExpr(e, field.pos);
						field.kind = FieldType.FProp("never", "default", t, e);
						return macro (untyped Object).defineProperty(this, $v{field.name}, { set:function(v) $i{setter}(v) });
						
					case [ "default"|"null"|"never", "default"|"null"|"never", _ ]:
						// nothing to do
						
					case _:
						Context.fatalError("JsProp: unsupported get/set combination. Supported: (get,set), (get,never) and (never,set) all without @:isVar.", field.pos);
				}
				
			case _:
				Context.fatalError("JsProp: unsupported type (must be a property).", field.pos);
		}
		return null;
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
	
	static function getConstructorFunction(fields:Array<Field>, superClass:SuperClass) : Function
	{
		var method : Field = null;
		
		for (field in fields) if (field.name == "new") { method = field; break; }
		
		if (method == null)
		{
			var superFuncArgs = getSuperFunctionArgs("new", superClass);
			if (superFuncArgs != null)
			{
				var superCall = ECall(macro super, superFuncArgs.map(function(p) return macro $i{p.name}));
				method = createMethod("new", superFuncArgs, macro:Void, { expr:superCall, pos:Context.currentPos() });
			}
			else
			{
				method = createMethod("new", [], macro:Void, macro {});
			}
			fields.push(method);
		}
		
		switch (method.kind)
		{
			case FieldType.FFun(f):
				return f;
				
			case _:
				Context.fatalError("JsProp: unexpected constructor type '" + method.kind + "'.", method.pos);
				return null;
		}
	}
	
	static function getHxUnserializeFunction(fields:Array<Field>, superClass:SuperClass) : Function
	{
		var method : Field = null;
		
		for (field in fields) if (field.name == "hxUnserialize") { method = field; break; }
		
		if (method == null)
		{
			var superFuncArgs = getSuperFunctionArgs("hxUnserialize", superClass);
			if (superFuncArgs != null)
			{
				var superCall = ECall(macro super.hxUnserialize, superFuncArgs.map(function(p) return macro $i{p.name}));
				method = createMethod("hxUnserialize", superFuncArgs, macro:Void, { expr:superCall, pos:Context.currentPos() } );
				method.access.push(Access.AOverride);
			}
			else
			{
				method = createMethod("hxUnserialize", [ { name:"s", type:(macro:haxe.Unserializer) } ], macro:Void, macro { s.unserializeObject(cast this); } );
				if (method.meta == null) method.meta = [];
				method.meta.push({ name:":access", params:[ macro haxe.Unserializer.unserializeObject ], pos:Context.currentPos() });
			}
			fields.push(method);
		}
		
		switch (method.kind)
		{
			case FieldType.FFun(f):
				return f;
				
			case _:
				Context.fatalError("JsProp: unexpected hxUnserialize method type '" + method.kind + "'.", method.pos);
				return null;
		}
	}
	
	static function ensureHxSerializeFunctionExists(fields:Array<Field>, superClass:SuperClass) : Void
	{
		for (field in fields) if (field.name == "hxSerialize") return;
		if (getSuperClassField("hxSerialize", superClass) != null) return;
		
		var method = createMethod("hxSerialize", [ { name:"s", type:(macro:haxe.Serializer) } ], macro:Void, macro { s.serializeFields(cast this); } );
		if (method.meta == null) method.meta = [];
		method.meta.push({ name:":access", params:[ macro haxe.Serializer.serializeFields ], pos:Context.currentPos() });
		fields.push(method);
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
	
	
	
	static function getSuperClassField(name:String, superClass:SuperClass) : ClassField
	{
		while (superClass != null)
		{
			var c = superClass.t.get();
			if (name == "new" && c.constructor != null) return c.constructor.get();
			var fields = c.fields.get().filter(function(f) return f.name == name);
			if (fields.length > 0) return fields[0];
			superClass = c.superClass;
		}
		return null;
	}
	
	static function getSuperFunctionArgs(name:String, superClass:SuperClass) : Array<FunctionArg>
	{
		var field = getSuperClassField(name, superClass);
		if (field != null)
		{
			switch (field.type)
			{
				case Type.TFun(args, ret): return args.map(toFunctionArg);
				case Type.TLazy(f):
					switch (f())
					{
						case Type.TFun(args, ret): return args.map(toFunctionArg);
						case _: Context.fatalError("Expected TFun: " + field.type, field.pos);
					}
				case _: Context.fatalError("Expected TFun: " + field.type, field.pos);
			}
		}
		return null;
	}
	
	static function toFunctionArg(a:{ name:String, opt:Bool, t:Type }) : FunctionArg
	{
		return { name: a.name, opt: a.opt, type: a.t.toComplexType(), value: null };
	}
	
	static function ensureNoExpr(e:Null<Expr>, pos:Position)
	{
		if (e != null)
		{
			Context.fatalError("Default value is not supported here.", pos);
		}
	}
}
