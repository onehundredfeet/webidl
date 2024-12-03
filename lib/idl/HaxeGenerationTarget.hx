package idl;
import idl.Data;
import haxe.macro.Expr;

using StringTools;
using idl.macros.MacroTools;


class HaxeGenerationTypeInfo {
	public final path:haxe.macro.TypePath;
	public final defn:haxe.macro.TypeDefinition;
	public final kind:idl.Data.DefinitionKind;
	public function new(path:haxe.macro.TypePath, defn:haxe.macro.TypeDefinition, kind:idl.Data.DefinitionKind) {
		this.path = path;
		this.defn = defn;
		this.kind = kind;
	}
}

abstract class HaxeGenerationTarget {
    var opts: Options;
    var _typeInfos : Map<String, HaxeGenerationTypeInfo>;
	var defaultPos : haxe.macro.Expr.Position = { file: "unknown", min: 0, max: 0 };
	
    public function new(opts: Options, typeInfos : Map<String, HaxeGenerationTypeInfo>) {
        this.opts = opts;
        this._typeInfos = typeInfos;
    }
    public abstract function makeNative( iname : String, midfix : String, fname : String, argc : Null<Int>, p : Position ) : Array<MetadataEntry>;
    public abstract function makeType( t : TypeAttr, isReturn:Bool ) : ComplexType;
    public abstract function makeVectorType( t : TypeAttr, vt : Type, vdim : Int, isReturn:Bool ): ComplexType;
    public abstract function getTargetCondition() : String;
    public abstract function getInterfaceTypeDefinitions(iname : String, pack : Array<String>, dfields : Array<Field>, p : Position) : Array<TypeDefinition>;

	public function addAttribute(iname : String, haxeName : String, f : idl.Data.Field, t : TypeAttr, p : Position) : Array<haxe.macro.Field> {
		var attribFields : Array<Field> = [];
		switch (t.t) {
			case TArray(at, sizeField):
				var et = t.getElementType();
				var cetr = makeType(et, true);
				var cet = makeType(et, false);
	
				attribFields.push({
					pos: p,
					name: "get" + haxeName,
					meta: makeNative(iname, "_get_", haxeName, null, p),
					kind: externalFunction([
						{
							name: "index",
							type: macro :Int
						}
					], cetr, macro return ${defVal(et)}),
					access: [APublic]
				});
				attribFields.push({
					pos: p,
					name: "set" + haxeName,
					meta: makeNative(iname, "_set_", haxeName, null, p),
					kind: externalFunction([
						{
							name: "index",
							type: macro :Int
						},
						{name: "_v", type: cet}
					], cetr, macro return ${defVal(et)}),
					access: [APublic]
				});
	
			default:
				var hasSet = t.attr == null || t.attr.indexOf(AReadOnly) < 0;
				var tt = makeType(t, false);
	
				var fkind = hasSet ? FProp("get", "set", tt) : FProp("get", "never", tt);
				attribFields.push({
					pos: p,
					name: haxeName,
					kind: fkind,
					access: [APublic],
				});
				attribFields.push({
					pos: p,
					name: "get_" + haxeName,
					meta: makeNative(iname, "_get_", haxeName, null, p),
					kind: externalFunction([], makeType(t, true), macro return ${defVal(t)}),
				});
				if (hasSet) {
					attribFields.push({
						pos: p,
						name: "set_" + haxeName,
						meta: makeNative(iname, "_set_", haxeName, null, p),
						kind: externalFunction([
							{
								name: "_v",
								type: tt
							}
						], tt, macro return ${defVal(t)})
					});
				}
				var vt:Type = null;
				var vta:TypeAttr = null;
				var vdim = 0;
	
				var isVector = switch (t.t) {
					case TVector(vvt, vvdim):
						vt = vvt;
						vdim = vvdim;
						vta = {t: vt, attr: t.attr};
						true;
					default: false;
				}
	
				if (isVector && false) {
					attribFields.push({
						pos: p,
						name: "set" + haxeName + vdim,
						meta: makeNative(iname, "_set", haxeName + vdim, null, p),
						access: [APublic, AInline],
						kind: FFun({
							ret: macro :Void,
							expr: macro return,
							args: [for (c in 0...vdim) {name: "_v" + c, type: makeType(vta, false)}],
						}),
					});
				}
		}

		return attribFields;
	}
	public function externalFunction(args:Array<FunctionArg>, ret : ComplexType = null, expr :Expr = null) : FieldType {
		return FFun({
			ret: ret,
			expr: needsStubs() ? expr : null,
			args: args,
		});
	
	}

	public function embeddedFunction(args:Array<FunctionArg>, ret : ComplexType = null, expr :Expr = null) : FieldType {
		return FFun({
			ret: ret,
			expr: expr,
			args: args,
		});
	
	}

    public function needsStubs() : Bool {
        return true;
    }
    private static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substring(1);
	}

    function makeName(name:String) {
		// name - list of comma separated prefixes
		if (opts.chopPrefix != null) {
			var prefixes = opts.chopPrefix.split(',');
			for (prefix in prefixes) {
				if (StringTools.startsWith(name, prefix)) {
					name = name.substr(prefix.length);
				}
			}
		}
		return capitalize(name);
	}

	function defVal( t : TypeAttr, p : Position = null ) : Expr {
		if (p == null) p = defaultPos;
		return switch( t.t ) {
		case TVoid: throw "assert";
		case TInt, TUInt, TShort, TInt64, TChar: { expr : EConst(CInt("0")), pos : p };
		case TFloat, TDouble: { expr : EConst(CFloat("0.")), pos : p };
		case TBool: { expr : EConst(CIdent("false")), pos : p };
		case TEnum(name): ECall(EField(EConst(CIdent(name)).at(p),"fromIndex").at(p), [EConst(CInt("0")).at(p)] ).at(p); //{ expr : , pos : p };
		case TCustom(id):
			var ex = { expr : EConst(CInt("0")), pos : p };
			var tp = TPath({ pack : [], name : id });

			if (_typeInfos.exists(id))  
				{ expr : ECast(ex, tp), pos : p };
			else
				{ expr : EConst(CIdent("null")), pos : p };
		default: 
			{ expr : EConst(CIdent("null")), pos : p };
		}
	}
}
